import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import MapLibreGLCall from './maplibre-gl-call.gts';
import MapLibreGLOn from './maplibre-gl-on.gts';
import MapLibreGLPopup from './maplibre-gl-popup.gts';
import MapLibreGLControl from './maplibre-gl-control.ts';
import MapLibreGLImage from './maplibre-gl-image.gts';
import MapLibreGLSource from './maplibre-gl-source.gts';
import MapLibreGLLayer from './maplibre-gl-layer.gts';
import MapLibreGLMarker from './maplibre-gl-marker.gts';

import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import { modifier } from 'ember-modifier';

import maplibregl, {
  type MapOptions,
  type Map as MaplibreMap,
  type MapContextEvent,
} from 'maplibre-gl';

import { registerDestructor } from '@ember/destroyable';

// Map instance reuse, following react-map-gl's reuseMaps pattern.
// See reuse: https://github.com/visgl/react-map-gl/blob/c41e00c/modules/react-maplibre/src/maplibre/maplibre.ts#L217-L269
// See recycle: https://github.com/visgl/react-map-gl/blob/c41e00c/modules/react-maplibre/src/maplibre/maplibre.ts#L342-L349
interface SavedMap {
  map: MaplibreMap;
  container: HTMLElement;
}

const savedMaps = new Map<string, SavedMap>();

/** Signature for {@link MapLibreGL}. */
export interface MapLibreGLSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * MapLibre map options (style, center, zoom, etc.). Passed once at construction; later changes are ignored.
     * The `container` property is managed internally and should be omitted.
     *
     * @see https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/
     */
    initOptions: Omit<MapOptions, 'container'>;

    /** Called once the map's style and tiles have loaded. Receives the map instance. */
    mapLoaded?: (map: MaplibreMap) => void;

    /**
     * Cache the WebGL map instance on teardown and reuse it on remount.
     * Avoids expensive context creation on repeated route transitions.
     * Only works when `initOptions.style` is a URL string.
     */
    reuseMaps?: boolean;

    /** Override the map constructor (e.g. for testing or mapbox-gl compatibility). */
    mapLib?: new (...args: unknown[]) => MaplibreMap;
  };
  Blocks: {
    /**
     * Yields an object with pre-bound child components and the map instance.
     * Available after the map has loaded.
     */
    default: [
      {
        /** Invoke a method on the map instance declaratively. */
        call: WithBoundArgs<typeof MapLibreGLCall, 'obj'>;
        /** Add a UI control (navigation, scale, etc.) to the map. */
        control: WithBoundArgs<typeof MapLibreGLControl, 'map' | 'parent'>;
        /** Load and register a custom image for use in symbol layers. */
        image: WithBoundArgs<typeof MapLibreGLImage, 'map'>;
        /** Add a rendering layer directly (without an explicit source component). */
        layer: WithBoundArgs<typeof MapLibreGLLayer, 'map'>;
        /** Place a draggable marker on the map. */
        marker: WithBoundArgs<typeof MapLibreGLMarker, 'map' | 'parent'>;
        /** Bind an event listener to the map. */
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
        /** Show a popup overlay on the map. */
        popup: WithBoundArgs<typeof MapLibreGLPopup, 'map'>;
        /** Add a data source (GeoJSON, vector tiles, etc.) to the map. */
        source: WithBoundArgs<typeof MapLibreGLSource, 'map'>;
        /** The underlying MapLibre map instance, or undefined before load. */
        instance: MaplibreMap | undefined;
        /** The Ember component instance (useful for associateDestroyableChild). */
        component: MapLibreGL;
      },
    ];
    /** Yielded when the map encounters a fatal error (e.g. WebGL context lost). */
    error: [ErrorEvent];
  };
}

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
export default class MapLibreGL extends Component<MapLibreGLSignature> {
  /** @internal */
  mapLibrary =
    this.args.mapLib ||
    (maplibregl.Map as new (...args: unknown[]) => MaplibreMap);
  /** @internal */
  @tracked mapLoaded = false;

  /** @internal */
  map?: MaplibreMap;

  /** @internal */
  @tracked error?: ErrorEvent;

  /** @internal */
  registerElement = modifier(
    (element: HTMLElement, [options]: [Omit<MapOptions, 'container'>]) => {
      if (this.map) return;

      const onLoad = () => {
        this.mapLoaded = true;
        this.args.mapLoaded?.(this.map as MaplibreMap);
      };

      const onError = (error: ErrorEvent) => {
        console.error('MapLibre GL error:', error);
        this.error = error;
      };

      const onContextLost = (event: MapContextEvent) => {
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
      const styleUrl =
        typeof options.style === 'string' ? options.style : undefined;
      const reused =
        this.args.reuseMaps && styleUrl ? savedMaps.get(styleUrl) : undefined;

      // Defined here so the destructor can clean it up if the component is
      // destroyed before 'style.load' fires on a reused map.
      // Uses on() instead of once() so that off() in the destructor can match the handler.
      const onStyleLoad = () => {
        this.map?.off('style.load', onStyleLoad);
        this.map?.fire('load');
      };

      // Type for MapLibre private internals we depend on for reuse.
      type MapInternals = {
        _container: HTMLElement;
        _resizeObserver?: ResizeObserver;
        _update: () => void;
      };

      // Guard: reuse relies on MapLibre private internals (_container, _update).
      // If a future MapLibre version removes them, fall through to fresh creation.
      const canReuse =
        reused &&
        '_container' in reused.map &&
        typeof (reused.map as unknown as MapInternals)._update === 'function';

      if (reused && canReuse && styleUrl) {
        savedMaps.delete(styleUrl);
        this.map = reused.map;
        const mapInternals = this.map as unknown as MapInternals;
        const oldContainer = reused.container;

        // Step 1: reparent MapLibre's internal DOM nodes into the new container.
        // Only move elements with maplibregl-* classes (canvas, controls, etc.) —
        // discard anything else (stale Ember template content, comment nodes).
        // MapLibre also adds 'maplibregl-map' to the container during construction,
        // so we add it to the new element (but don't overwrite consumer's classes).
        element.classList.add('maplibregl-map');
        for (const child of [...oldContainer.childNodes]) {
          const isMapInternal =
            child instanceof Element &&
            [...child.classList].some((c) => c.startsWith('maplibregl-'));
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
          this.map.jumpTo({ center: options.center, zoom: options.zoom });
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
          console.warn(
            'MapLibre reuse failed: expected _container/_update internals missing',
          );
          if (styleUrl) savedMaps.delete(styleUrl);
          reused.map.remove();
        }
        try {
          this.map = new this.mapLibrary({
            ...options,
            container: element,
          });

          this.map.on('load', onLoad);
        } catch (error) {
          console.error(
            'Failed to initialize map (likely WebGL issue):',
            error,
          );
          this.error = error as ErrorEvent;
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
              /* already dead */
            }
            return;
          }

          // Recycle: see https://github.com/visgl/react-map-gl/blob/c41e00c/modules/react-maplibre/src/maplibre/maplibre.ts#L342-L349
          const existing = savedMaps.get(styleUrl);
          if (existing) {
            try {
              existing.map.remove();
            } catch {
              /* ignore */
            }
          }
          savedMaps.set(styleUrl, {
            map: this.map,
            container: this.map.getContainer(),
          });
        } else {
          this.map?.remove();
        }
      });
    },
  );

  <template>
    <div {{this.registerElement @initOptions}} ...attributes>
      {{#if this.mapLoaded}}
        {{yield
          (hash
            call=(component MapLibreGLCall obj=this.map)
            control=(component MapLibreGLControl map=this.map parent=this)
            image=(component MapLibreGLImage map=this.map parent=this)
            layer=(component MapLibreGLLayer map=this.map parent=this)
            marker=(component MapLibreGLMarker map=this.map parent=this)
            on=(component MapLibreGLOn eventSource=this.map)
            popup=(component MapLibreGLPopup map=this.map)
            source=(component MapLibreGLSource map=this.map parent=this)
            instance=this.map
            component=this
          )
        }}
      {{else if this.error}}
        {{#if (has-block "inverse")}}
          {{yield this.error to="error"}}
        {{else}}
          {{! template-lint-disable no-log }}
          {{log "error rendering maplibre-gl" this.error}}
        {{/if}}
      {{/if}}
    </div>
  </template>
}
