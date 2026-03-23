import Component from '@glimmer/component';
import type maplibregl from 'maplibre-gl';
type PublicMethodKeys<T> = {
    [K in keyof T]: K extends `_${string}` ? never : T[K] extends (...args: any[]) => any ? K : never;
}[keyof T] & keyof T;
/**
 * Public function method surface of the MapLibre [Map ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/).
 *
 * Excludes `_`-prefixed internals and non-method properties so `@func` only
 * auto-completes callable public methods.
 */
export type MapInstance = Pick<maplibregl.Map, PublicMethodKeys<maplibregl.Map>>;
/** Signature for {@link MapLibreGLCall}. */
export interface MapLibreGLCallSignature {
    Args: {
        /** The object to call the method on — typically the map instance (pre-bound by parent). */
        obj: MapInstance;
        /** Name of the method to invoke (e.g. "flyTo", "setStyle", "resize"). */
        func: keyof MapInstance;
        /** Arguments to pass to the method. */
        positionalArguments: unknown[];
        /** Optional callback that receives the method's return value. */
        onResp?: (result: unknown) => void;
    };
}
/**
 * Declaratively invokes a method on the map instance. Re-invokes reactively
 * when `@func` or `@positionalArguments` reference changes — Glimmer's
 * `(array)`/`(hash)` helpers memoize references, so the method only fires
 * when inputs actually change.
 *
 * @access `<MapLibreGL>` as `map.call`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.call @func="flyTo" @positionalArguments={{array (hash center=this.target zoom=14)}} />
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLCall extends Component<MapLibreGLCallSignature> {
    /** @internal */
    get onResp(): (result: unknown) => void;
    /** @internal */
    call: (obj: MapInstance, func: keyof MapInstance, positionalArguments: unknown[]) => void;
}
export {};
//# sourceMappingURL=maplibre-gl-call.d.ts.map