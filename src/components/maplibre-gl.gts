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

export interface MapLibreGLArgs {
  /**
   * An options hash to pass on to the [maplibre-gl-js instance](https://www.mapbox.com/maplibre-gl-js/api/).
   * This is only used during map construction, and updates will have no effect.
   */
  initOptions: Omit<MapOptions, 'container'>;

  /**
   * An action function to call when the map has finished loading.
   * Note that the component does not yield until the map has loaded,
   * so this is the only way to listen for the mapbox load event.
   */
  mapLoaded?: (map: MaplibreMap) => void;

  /**
   * If true, the map instance is cached when the component is destroyed
   * and reused when a new MapLibreGL component mounts. This avoids
   * expensive WebGL context creation on repeated route transitions.
   * Follows the same pattern as react-map-gl's reuseMaps prop.
   */
  reuseMaps?: boolean;

  mapLib?: new (...args: unknown[]) => MaplibreMap;
}

export interface MapLibreGLSignature {
  Element: HTMLDivElement;
  Args: MapLibreGLArgs;
  Blocks: {
    default: [
      {
        call: WithBoundArgs<typeof MapLibreGLCall, 'obj'>;
        control: WithBoundArgs<typeof MapLibreGLControl, 'map' | 'parent'>;
        image: WithBoundArgs<typeof MapLibreGLImage, 'map'>;
        layer: WithBoundArgs<typeof MapLibreGLLayer, 'map'>;
        marker: WithBoundArgs<typeof MapLibreGLMarker, 'map' | 'parent'>;
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
        popup: WithBoundArgs<typeof MapLibreGLPopup, 'map'>;
        source: WithBoundArgs<typeof MapLibreGLSource, 'map'>;
        instance: MaplibreMap | undefined;
        component: MapLibreGL;
      },
    ];
    error: [ErrorEvent];
  };
}

export default class MapLibreGL extends Component<MapLibreGLSignature> {
  mapLibrary =
    this.args.mapLib ||
    (maplibregl.Map as new (...args: unknown[]) => MaplibreMap);
  @tracked mapLoaded = false;

  map?: MaplibreMap;

  @tracked error?: ErrorEvent;

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
