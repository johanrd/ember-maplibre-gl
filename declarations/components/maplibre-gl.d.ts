import Component from '@glimmer/component';
import MapLibreGLCall from './maplibre-gl-call';
import MapLibreGLOn from './maplibre-gl-on';
import MapLibreGLPopup from './maplibre-gl-popup';
import MapLibreGLControl from './maplibre-gl-control';
import MapLibreGLImage from './maplibre-gl-image';
import MapLibreGLSource from './maplibre-gl-source';
import MapLibreGLLayer from './maplibre-gl-layer';
import MapLibreGLMarker from './maplibre-gl-marker';
import type { WithBoundArgs } from '@glint/template';
import maplibregl, { type MapOptions, type Map as MaplibreMap } from 'maplibre-gl';
/**
 * MapLibre [MapOptions ↗](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/) without `container`, which is managed internally.
 */
export type MapInitOptions = Omit<MapOptions, 'container'>;
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
        initOptions: MapInitOptions;
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
                image: WithBoundArgs<typeof MapLibreGLImage, 'map' | 'parent'>;
                /** Add a rendering layer directly (without an explicit source component). */
                layer: WithBoundArgs<typeof MapLibreGLLayer, 'map' | 'parent'>;
                /** Place a draggable marker on the map. */
                marker: WithBoundArgs<typeof MapLibreGLMarker, 'map' | 'parent'>;
                /** Bind an event listener to the map. */
                on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
                /** Show a popup overlay on the map. */
                popup: WithBoundArgs<typeof MapLibreGLPopup, 'map'>;
                /** Add a data source (GeoJSON, vector tiles, etc.) to the map. */
                source: WithBoundArgs<typeof MapLibreGLSource, 'map' | 'parent'>;
                /** The underlying MapLibre map instance (always defined inside the default block). */
                instance: MaplibreMap | undefined;
                /** The Ember component instance (useful for associateDestroyableChild). */
                component: MapLibreGL;
            }
        ];
        /** Yielded when the map encounters a fatal error (e.g. WebGL context lost). Receives an `Error` with a `.message` property. */
        error: [Error];
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
    mapLibrary: new (...args: unknown[]) => MaplibreMap;
    /** @internal */
    mapLoaded: boolean;
    /** @internal */
    map?: MaplibreMap;
    /** @internal */
    error?: Error;
    /** @internal */
    registerElement: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: [Omit<maplibregl.MapOptions, "container">];
            Named: import("ember-modifier/-private/signature").EmptyObject;
        };
        Element: HTMLElement;
    }>;
}
//# sourceMappingURL=maplibre-gl.d.ts.map