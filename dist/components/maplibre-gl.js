import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import MapLibreGLCall from './maplibre-gl-call.js';
import MapLibreGLOn from './maplibre-gl-on.js';
import MapLibreGLPopup from './maplibre-gl-popup.js';
import MapLibreGLControl from './maplibre-gl-control.js';
import MapLibreGLImage from './maplibre-gl-image.js';
import MapLibreGLSource from './maplibre-gl-source.js';
import MapLibreGLLayer from './maplibre-gl-layer.js';
import MapLibreGLMarker from './maplibre-gl-marker.js';
import { hash } from '@ember/helper';
import { modifier } from 'ember-modifier';
import maplibregl from 'maplibre-gl';
import { registerDestructor } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';
import { g, i } from 'decorator-transforms/runtime-esm';

const savedMaps = new Map();
/**
 * MapLibre [MapOptions ↗](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/) without `container`, which is managed internally.
 */
/** Signature for {@link MapLibreGL}. */

/**
 * The root map component. Renders a MapLibre GL JS map and yields pre-bound child
 * components for adding sources, layers, markers, popups, controls, and event listeners.
 *
 * The block is only rendered after the map has fully loaded.
 *
 * @example
 * ```gts
 * <MapLibreGL
 *   @initOptions={{hash style="https://demotiles.maplibre.org/style.json" center=(array 0 0) zoom=1}}
 *   @mapLoaded={{this.onMapLoaded}}
 *   as |map|
 * >
 *   <map.source @options={{this.geojsonSource}} as |source|>
 *     <source.layer @options={{this.circleLayer}} />
 *   </map.source>
 *   <map.marker @lngLat={{this.markerPosition}} />
 *   <map.on @event="click" @action={{this.onClick}} />
 * </MapLibreGL>
 * ```
 */
class MapLibreGL extends Component {
  /** @internal */mapLibrary = this.args.mapLib || maplibregl.Map;
  /** @internal */
  static {
    g(this.prototype, "mapLoaded", [tracked], function () {
      return false;
    });
  }
  #mapLoaded = (i(this, "mapLoaded"), void 0);
  /** @internal */map;
  /** @internal */
  static {
    g(this.prototype, "error", [tracked]);
  }
  #error = (i(this, "error"), void 0);
  /** @internal */registerElement = modifier((element, [options]) => {
    if (this.map) return;
    const onLoad = () => {
      this.mapLoaded = true;
      this.args.mapLoaded?.(this.map);
    };
    const onError = event => {
      console.error('MapLibre GL error:', event.error?.message ?? event.error);
      this.error = event.error instanceof Error ? event.error : new Error(event.error.message);
    };
    const onContextLost = event => {
      console.warn('WebGL context lost', event);
      event.originalEvent.preventDefault();
    };
    const onContextRestored = () => {
      console.log('WebGL context restored');
      this.map?.resize();
      this.map?.redraw();
    };
    // Reuse is only enabled when style is a URL string — object styles can't be
    // reliably compared, so we skip pooling for them.
    // Construction-only options (attributionControl, hash, interactive, etc.) are not
    // reapplied on reuse — same limitation as react-map-gl. Callers sharing a style
    // URL should use compatible initOptions.
    const styleUrl = typeof options.style === 'string' ? options.style : undefined;
    const reused = this.args.reuseMaps && styleUrl ? savedMaps.get(styleUrl) : undefined;
    // Defined here so the destructor can clean it up if the component is
    // destroyed before 'style.load' fires on a reused map.
    // Uses on() instead of once() so that off() in the destructor can match the handler.
    const onStyleLoad = () => {
      this.map?.off('style.load', onStyleLoad);
      this.map?.fire('load');
    };
    // Type for MapLibre private internals we depend on for reuse.

    // Guard: reuse relies on MapLibre private internals (_container, _update).
    // If a future MapLibre version removes them, fall through to fresh creation.
    const canReuse = reused && '_container' in reused.map && typeof reused.map._update === 'function';
    if (reused && canReuse && styleUrl) {
      savedMaps.delete(styleUrl);
      this.map = reused.map;
      const mapInternals = this.map;
      const oldContainer = reused.container;
      // Step 1: reparent MapLibre's internal DOM nodes into the new container.
      // Only move elements with maplibregl-* classes (canvas, controls, etc.) —
      // discard anything else (stale Ember template content, comment nodes).
      // MapLibre also adds 'maplibregl-map' to the container during construction,
      // so we add it to the new element (but don't overwrite consumer's classes).
      element.classList.add('maplibregl-map');
      for (const child of [...oldContainer.childNodes]) {
        const isMapInternal = child instanceof Element && [...child.classList].some(c => c.startsWith('maplibregl-'));
        if (isMapInternal) element.appendChild(child);
      }
      // Step 2: replace the internal container reference
      mapInternals._container = element;
      // Step 3: reconnect ResizeObserver to new container
      if (mapInternals._resizeObserver) {
        mapInternals._resizeObserver.disconnect();
        mapInternals._resizeObserver.observe(element);
      }
      // Step 4: apply new options.
      // Note: react-map-gl calls setProps({styleDiffing: false}) here, which may change
      // the style via setStyle(). We don't need that because savedMaps is keyed by style
      // URL — we only reuse maps with a matching style.
      this.map.resize();
      if (options.center !== undefined || options.zoom !== undefined) {
        this.map.jumpTo({
          center: options.center,
          zoom: options.zoom
        });
      }
      // Step 5: register load listener BEFORE firing, then simulate load event
      this.map.on('load', onLoad);
      if (this.map.isStyleLoaded()) {
        this.map.fire('load');
      } else {
        this.map.on('style.load', onStyleLoad);
      }
      // Force redraw
      mapInternals._update();
    } else {
      if (reused) {
        // Internals missing — can't reuse, destroy the cached map.
        // This means a MapLibre upgrade removed the private APIs we depend on.
        console.warn('MapLibre reuse failed: expected _container/_update internals missing');
        if (styleUrl) savedMaps.delete(styleUrl);
        reused.map.remove();
      }
      try {
        this.map = new this.mapLibrary({
          ...options,
          container: element
        });
        this.map.on('load', onLoad);
      } catch (error) {
        console.error('Failed to initialize map (likely WebGL issue):', error);
        this.error = error instanceof Error ? error : new Error(String(error));
        return;
      }
    }
    this.map.on('error', onError);
    this.map.on('webglcontextlost', onContextLost);
    this.map.on('webglcontextrestored', onContextRestored);
    registerDestructor(this, () => {
      this.map?.off('load', onLoad);
      this.map?.off('style.load', onStyleLoad);
      this.map?.off('error', onError);
      this.map?.off('webglcontextlost', onContextLost);
      this.map?.off('webglcontextrestored', onContextRestored);
      if (this.args.reuseMaps && this.map && styleUrl) {
        // Don't pool broken maps. getStyle() returns null when the style hasn't loaded,
        // and throws when the map is dead (e.g. WebGL context lost). Either way, the map
        // is unusable — destroy it instead of caching. react-map-gl doesn't do this check;
        // it's our defensive addition since WebGL context loss can happen between teardown steps.
        try {
          if (!this.map.getStyle()) throw new Error();
        } catch {
          try {
            this.map.remove();
          } catch {
            /* already dead */}
          return;
        }
        // Recycle: see https://github.com/visgl/react-map-gl/blob/c41e00c/modules/react-maplibre/src/maplibre/maplibre.ts#L342-L349
        const existing = savedMaps.get(styleUrl);
        if (existing) {
          try {
            existing.map.remove();
          } catch {
            /* ignore */}
        }
        savedMaps.set(styleUrl, {
          map: this.map,
          container: this.map.getContainer()
        });
      } else {
        this.map?.remove();
      }
    });
  });
  static {
    setComponentTemplate(precompileTemplate("<div {{this.registerElement @initOptions}} ...attributes>\n  {{#if this.mapLoaded}}\n    {{yield (hash call=(component MapLibreGLCall obj=this.map) control=(component MapLibreGLControl map=this.map parent=this) image=(component MapLibreGLImage map=this.map parent=this) layer=(component MapLibreGLLayer map=this.map parent=this) marker=(component MapLibreGLMarker map=this.map parent=this) on=(component MapLibreGLOn eventSource=this.map) popup=(component MapLibreGLPopup map=this.map) source=(component MapLibreGLSource map=this.map parent=this) instance=this.map component=this)}}\n  {{else if this.error}}\n    {{#if (has-block \"error\")}}\n      {{yield this.error to=\"error\"}}\n    {{/if}}\n  {{/if}}\n</div>", {
      strictMode: true,
      scope: () => ({
        hash,
        MapLibreGLCall,
        MapLibreGLControl,
        MapLibreGLImage,
        MapLibreGLLayer,
        MapLibreGLMarker,
        MapLibreGLOn,
        MapLibreGLPopup,
        MapLibreGLSource
      })
    }), this);
  }
}

export { MapLibreGL as default };
//# sourceMappingURL=maplibre-gl.js.map
