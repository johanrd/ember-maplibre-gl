import Component from '@glimmer/component';
import MapLibreGLOn from './maplibre-gl-on';
import type MapLibreGL from './maplibre-gl';
import type { WithBoundArgs } from '@glint/template';
import type { Evented, IControl } from 'maplibre-gl';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';
/**
 * Resolves toMapLibre [ControlPosition ↗](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/ControlPosition/) type.
 *
 * One of `"top-left"`, `"top-right"`, `"bottom-left"`, or `"bottom-right"`.
 */
export type ControlPosition = Parameters<maplibregl.Map['addControl']>['1'];
/** Signature for {@link MapLibreGLControl}. */
export interface MapLibreGLControlSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** A MapLibre IControl instance. Controls that extend Evented (e.g. `GeolocateControl`) support event binding via the yielded `on` component. */
        control: IControl;
        /** Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". */
        position: ControlPosition;
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
    Blocks: {
        /** Yields an `on` component for listening to control events (e.g. geolocate). */
        default: [
            {
                /** Listen to control events. Pre-bound with eventSource. Only works for controls that extend Evented. */
                on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
            }
        ];
    };
}
/**
 * Adds a UI control to the map (navigation, scale, attribution, geolocation, etc.).
 * The control is removed when the component is destroyed. Reactively updates
 * when `@control` or `@position` changes.
 *
 * @access `<MapLibreGL>` as `map.control`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.control @control={{this.navControl}} @position="top-right" />
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLControl extends Component<MapLibreGLControlSignature> {
    /** @internal */
    private _currentControl?;
    private _currentPosition?;
    /** @internal */
    constructor(owner: Owner, args: MapLibreGLControlSignature['Args']);
    /** @internal */
    updateControl: (control: IControl, position: MapLibreGLControlSignature["Args"]["position"]) => void;
    /** @internal */
    get eventSource(): Evented | undefined;
}
//# sourceMappingURL=maplibre-gl-control.d.ts.map