import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type MapLibreGL from './maplibre-gl.gts';
import {
  associateDestroyableChild,
  isDestroyed,
  isDestroying,
  registerDestructor,
} from '@ember/destroyable';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';

/** Signature for {@link MapLibreGLImage}. */
export interface MapLibreGLImageSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: maplibregl.Map;
    /** URL of the image to load. Supports PNG, JPEG, and SVG formats. */
    url?: Parameters<maplibregl.Map['loadImage']>['0'];
    /** Name to register the image under. Use this name in symbol layer `icon-image`. */
    name: Parameters<maplibregl.Map['addImage']>['0'];
    /** Image options (pixelRatio, sdf) passed to `map.addImage`. */
    options?: Parameters<maplibregl.Map['addImage']>['2'];
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
 * Yielded by `<MapLibreGL>` as `map.image`. Does not yield any block content.
 *
 * @example
 * ```gts
 * <map.image @url="/icons/pin.png" @name="pin-icon" @onLoad={{this.onImageReady}} />
 * <map.image @url="/icons/marker.svg" @name="svg-marker" @width={{32}} @height={{32}} />
 * ```
 */
export default class MapLibreGLImage extends Component<MapLibreGLImageSignature> {
  /** @internal */
  @tracked _lastName?: string;

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
    return /\.svg$/.test(url);
  }

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLImageSignature['Args']) {
    super(owner, args);

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this.args.name && this.args.map?.hasImage(this.args.name)) {
          this.args.map.removeImage(this.args.name);
        }
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
    // If the component already has added an image to the map, remove it
    if (this._lastName && this.args.map.hasImage(this._lastName)) {
      this.args.map.removeImage(this._lastName);
    }

    if (!url) {
      return;
    }

    if (this.isSvg) {
      const image = new Image();
      if (width) {
        image.width = width;
      }

      if (height) {
        image.height = height;
      }

      image.onload = () => this._onImage(url, name, options, image);
      image.onerror = (event) => this._onSvgErr(url, event);
      image.src = url;
    } else {
      this.args.map
        .loadImage(url)
        .then(({ data }) => this._onImage(url, name, options, data))
        .catch((error) => this.onError(error));
    }
  };

  /** @internal */
  _onImage = (
    url: MapLibreGLImageSignature['Args']['url'],
    name: MapLibreGLImageSignature['Args']['name'],
    options?: MapLibreGLImageSignature['Args']['options'],
    image?: Parameters<maplibregl.Map['addImage']>[1],
  ) => {
    if (isDestroying(this) || isDestroyed(this)) {
      return;
    }

    if (this.args.url !== url) {
      // image has changed since we started loading
      return;
    }

    this.args.map.addImage(name, image!, options);

    this._lastName = name;

    this.onLoad();
  };

  /** @internal */
  _onSvgErr = (_url: string, event: Event | string) => {
    this.onError(new SvgLoadError('Failed to load svg', event));
  };

  <template>{{this.loadImage @url @name @options @width @height}}</template>
}
