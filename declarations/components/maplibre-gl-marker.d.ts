import Component from '@glimmer/component';
import { Marker, type MarkerOptions, type LngLatLike } from 'maplibre-gl';
import MapLibreGLOn from './maplibre-gl-on';
import MapLibreGLPopup from './maplibre-gl-popup';
import type MapLibreGL from './maplibre-gl';
import type { WithBoundArgs } from '@glint/template';
import type Owner from '@ember/owner';
import type maplibregl from 'maplibre-gl';
/** Signature for {@link MapLibreGLMarker}. */
export interface MapLibreGLMarkerSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** Geographic position of the marker. Reactively updates when changed. */
        lngLat: LngLatLike;
        /** Marker configuration passed once at construction (draggable, color, anchor, etc.). */
        initOptions?: MarkerOptions;
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
    Blocks: {
        /** Yields a pre-bound `popup` (attached to this marker) and `on` for marker events (e.g. dragend). */
        default: [
            {
                /** Attach a popup to this marker. Pre-bound with map and marker reference. */
                popup: WithBoundArgs<typeof MapLibreGLPopup, 'map' | 'marker'>;
                /** Listen to marker events (drag, dragstart, dragend). Pre-bound with eventSource. */
                on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
            }
        ];
    };
}
/**
 * Places a marker on the map at a given position. The block content becomes the
 * marker's DOM element, so you can render any Ember template inside it.
 *
 * @access `<MapLibreGL>` as `map.marker`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.marker @lngLat={{array -96.79 32.77}} @initOptions={{hash draggable=true}} as |marker|>
 *     <marker.popup>
 *       <p>Hello from Dallas!</p>
 *     </marker.popup>
 *     <marker.on @event="dragend" @action={{this.onDragEnd}} />
 *   </map.marker>
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLMarker extends Component<MapLibreGLMarkerSignature> {
    /** @internal */
    marker: Marker | undefined;
    /** @internal */
    domContent: HTMLDivElement;
    /** @internal */
    constructor(owner: Owner, args: MapLibreGLMarkerSignature['Args']);
    /** @internal */
    get markerOptions(): MarkerOptions;
    private _prevLngLat?;
    /** @internal */
    updateMarker: (lngLat: LngLatLike) => void;
}
//# sourceMappingURL=maplibre-gl-marker.d.ts.map