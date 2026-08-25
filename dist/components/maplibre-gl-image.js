import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { associateDestroyableChild, registerDestructor, isDestroying, isDestroyed } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/** Signature for {@link MapLibreGLImage}. */
function noop() {}
/** Error thrown when an SVG image fails to load. Contains the original load event. */
class SvgLoadError extends Error {
  event;
  constructor(message, event) {
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
class MapLibreGLImage extends Component {
  /** @internal */_lastName;
  _lastLoadUrl;
  _lastLoadName;
  _lastLoadWidth;
  _lastLoadHeight;
  _lastLoadOptions;
  /** @internal */
  get onError() {
    return this.args.onError || noop;
  }
  /** @internal */
  get onLoad() {
    return this.args.onLoad || noop;
  }
  /** @internal */
  get isSvg() {
    const url = this.args.url;
    if (!url || typeof url !== 'string') {
      return false;
    }
    return /\.svg(?:[?#]|$)/i.test(url) || url.startsWith('data:image/svg+xml');
  }
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLImage` component', args.map);
    assert('`name` argument is required for `MapLibreGLImage` component', args.name);
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
  loadImage = (url, name, options, width, height) => {
    // Skip if nothing has changed (avoids redundant loads on re-render)
    if (url === this._lastLoadUrl && name === this._lastLoadName && width === this._lastLoadWidth && height === this._lastLoadHeight && options === this._lastLoadOptions) return;
    this._lastLoadUrl = url;
    this._lastLoadName = name;
    this._lastLoadWidth = width;
    this._lastLoadHeight = height;
    this._lastLoadOptions = options;
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
      image.onerror = event => this._onSvgErr(url, event);
      image.src = url;
    } else {
      this.args.map.loadImage(url).then(({
        data
      }) => this._onImage(url, name, options, data)).catch(error => this.onError(error));
    }
  };
  /** @internal */
  _onImage = (url, name, options, image) => {
    if (isDestroying(this) || isDestroyed(this)) {
      return;
    }
    if (this.args.url !== url || this.args.name !== name) {
      // url or name has changed since we started loading
      return;
    }
    this.args.map.addImage(name, image, options);
    this._lastName = name;
    this.onLoad();
  };
  /** @internal */
  _onSvgErr = (_url, event) => {
    this.onError(new SvgLoadError('Failed to load svg', event));
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.loadImage @url @name @options @width @height}}", {
      strictMode: true
    }), this);
  }
}

export { SvgLoadError, MapLibreGLImage as default };
//# sourceMappingURL=maplibre-gl-image.js.map
