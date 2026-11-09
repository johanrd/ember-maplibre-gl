import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import type MapLibreGL from './maplibre-gl.gts';
import {
  associateDestroyableChild,
  isDestroyed,
  isDestroying,
  registerDestructor,
} from '@ember/destroyable';
import { buildWaiter } from '@ember/test-waiters';
import { beginWait } from '../-private/wait.ts';
import type { Map as MaplibreMap, StyleImage } from 'maplibre-gl';
import type Owner from '@ember/owner';
import {
  consumeStyleRevision,
  isStyleLoaded,
} from '../-private/style-revision.ts';

/**
 * Options passed to MapLibre's [map.addImage ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/#addimage).
 *
 * Supports `pixelRatio` (for HiDPI images) and `sdf` (to enable runtime recoloring).
 *
 */
export type ImageOptions = Parameters<MaplibreMap['addImage']>['2'];

/** Signature for {@link MapLibreGLImage}. */
export interface MapLibreGLImageSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: MaplibreMap;
    /** URL of the image to load. Supports PNG, JPEG, and SVG formats. */
    url?: Parameters<MaplibreMap['loadImage']>['0'];
    /** Name to register the image under. Use this name in symbol layer `icon-image`. */
    name: Parameters<MaplibreMap['addImage']>['0'];
    /** Image options (pixelRatio, sdf) passed to `map.addImage`. */
    options?: ImageOptions;
    /** Explicit width for SVG images (ignored for raster formats). */
    width?: HTMLImageElement['width'];
    /** Explicit height for SVG images (ignored for raster formats). */
    height?: HTMLImageElement['height'];
    /** Called when the image has been loaded and added to the map. */
    onLoad?: () => void;
    /** Called if the image fails to load. */
    onError?: (err: unknown) => void;
    /** Parent component for destroyable association (pre-bound by parent). */
    parent?: MapLibreGL;
  };
}

function noop() {}

// Holds settled() open while an image loads, so it is on the map once
// `await render()` returns.
const imageWaiter = buildWaiter('ember-maplibre-gl:image-load');

/** Error thrown when an SVG image fails to load. Contains the original load event. */
export class SvgLoadError extends Error {
  event: Event | string;

  constructor(message: string, event: Event | string) {
    super(message);
    this.event = event;
  }
}

/**
 * Loads an image from a URL and registers it on the map for use in symbol layers.
 * Handles both raster (PNG/JPEG via `map.loadImage`) and SVG images (via `<img>`).
 * The image is removed from the map when the component is destroyed.
 *
 * @access `<MapLibreGL>` as `map.image`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.image @url="/icons/pin.png" @name="pin-icon" @onLoad={{this.onImageReady}} />
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLImage extends Component<MapLibreGLImageSignature> {
  /** @internal The name this component's image is on the map under. */
  _lastName?: string;
  private _lastLoadUrl?: typeof this.args.url;
  private _lastLoadName?: string;
  private _lastLoadWidth?: typeof this.args.width;
  private _lastLoadHeight?: typeof this.args.height;
  private _lastLoadOptions?: typeof this.args.options;
  private _endLoadWait?: () => void;
  // Kept to add the image again, without a new load, after the style changes.
  private _image?: Parameters<MaplibreMap['addImage']>[1];
  private _added?: StyleImage;

  /** @internal */
  get onError() {
    return this.args.onError || noop;
  }
  /** @internal */
  get onLoad() {
    return this.args.onLoad || noop;
  }

  /** @internal */
  get isSvg(): boolean {
    const url = this.args.url;
    if (!url || typeof url !== 'string') {
      return false;
    }
    return /\.svg(?:[?#]|$)/i.test(url) || url.startsWith('data:image/svg+xml');
  }

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLImageSignature['Args']) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLImage` component',
      args.map,
    );
    assert(
      '`name` argument is required for `MapLibreGLImage` component',
      args.name,
    );

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      this._endLoadWait?.();
      try {
        this.removeFromStyle();
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  /** @internal */
  loadImage = (
    url: MapLibreGLImageSignature['Args']['url'],
    name: MapLibreGLImageSignature['Args']['name'],
    options?: MapLibreGLImageSignature['Args']['options'],
    width?: MapLibreGLImageSignature['Args']['width'],
    height?: MapLibreGLImageSignature['Args']['height'],
  ) => {
    consumeStyleRevision(this.args.map);

    if (
      url === this._lastLoadUrl &&
      name === this._lastLoadName &&
      width === this._lastLoadWidth &&
      height === this._lastLoadHeight &&
      options === this._lastLoadOptions
    ) {
      this.addToStyle();
      return;
    }
    this._lastLoadUrl = url;
    this._lastLoadName = name;
    this._lastLoadWidth = width;
    this._lastLoadHeight = height;
    this._lastLoadOptions = options;

    // A newer load replaces any in-flight one, whose result _onImage discards.
    this._endLoadWait?.();
    this.removeFromStyle();
    this._image = undefined;

    if (!url) {
      return;
    }

    const endWait = beginWait(imageWaiter, `the image "${name}"`);
    this._endLoadWait = endWait;

    if (this.isSvg) {
      const image = new Image();
      if (width) {
        image.width = width;
      }

      if (height) {
        image.height = height;
      }

      const loaded = new Promise<void>((resolve, reject) => {
        image.onload = () => resolve();
        image.onerror = reject;
        image.src = url;
      });
      void loaded
        .then(
          () => this._onImage(url, name, image),
          (event: Event | string) => this._onSvgErr(url, event),
        )
        .catch((error) => this.onError(error))
        .finally(endWait);
    } else {
      this.args.map
        .loadImage(url)
        .then(({ data }) => this._onImage(url, name, data))
        .catch((error) => this.onError(error))
        .finally(endWait);
    }
  };

  /** @internal */
  _onImage = (
    url: MapLibreGLImageSignature['Args']['url'],
    name: MapLibreGLImageSignature['Args']['name'],
    image: Parameters<MaplibreMap['addImage']>[1],
  ) => {
    if (isDestroying(this) || isDestroyed(this)) {
      return;
    }

    if (this.args.url !== url || this.args.name !== name) {
      // url or name has changed since we started loading
      return;
    }

    this._image = image;
    this.addToStyle();
    this.onLoad();
  };

  // Does nothing while the style loads; the revision bump on 'style.load' calls it again.
  // An image the style's sprite already has under this name is left in place.
  private addToStyle() {
    const { map, name, options } = this.args;
    if (!this._image || !isStyleLoaded(map) || map.hasImage(name)) return;
    map.addImage(name, this._image, options);
    this._lastName = name;
    this._added = map.getImage(name);
  }

  private removeFromStyle() {
    const { map } = this.args;
    const name = this._lastName;
    this._lastName = undefined;
    if (!name || !map.style) return;
    const image = map.getImage(name);
    if (image && this.isOurs(image)) map.removeImage(name);
  }

  // A context restore puts back a copy with the same version; a sprite image has none,
  // and one that replaces ours gets a higher one.
  private isOurs(image: StyleImage) {
    const added = this._added;
    if (!added) return false;
    return (
      image === added ||
      (image.version === added.version &&
        image.data.width === added.data.width &&
        image.data.height === added.data.height)
    );
  }

  /** @internal */
  _onSvgErr = (_url: string, event: Event | string) => {
    this.onError(new SvgLoadError('Failed to load svg', event));
  };

  <template>{{this.loadImage @url @name @options @width @height}}</template>
}
