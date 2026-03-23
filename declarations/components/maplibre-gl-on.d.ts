import type { Evented } from 'maplibre-gl';
/** Args for the `MapLibreGLOn` template-only component. */
interface Args {
    /** The event name to listen for (e.g. "click", "moveend", "dragend"). */
    event: string;
    /** Callback invoked when the event fires. Receives the MapLibre event object. */
    action: (...args: any[]) => void;
    /** The object to listen on — map, marker, popup, or control (pre-bound by parent). */
    eventSource?: Evented;
    /** Optional layer ID to scope map events to features in a specific layer. */
    layerId?: string;
}
/**
 * Resource-based event binding helper. Registers an event listener and automatically
 * removes it on cleanup. Used internally by the `MapLibreGLOn` template component.
 */
export declare function mapOn(event: string, action: (...args: any[]) => void, eventSource?: Evented, layerId?: string): void;
/**
 * Declaratively binds an event listener to a map, marker, or popup. Automatically
 * cleans up the listener when the component is destroyed.
 *
 * When used with `@layerId`, the event only fires for features in that layer.
 *
 * @access `<MapLibreGL>` as `map.on`, `<map.marker>` as `marker.on`, `<map.popup>` as `popup.on`, `<map.control>` as `control.on`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.on @event="click" @action={{this.handleClick}} />
 *   <map.on @event="click" @layerId="my-layer" @action={{this.handleLayerClick}} />
 * </MapLibreGL>
 * ```
 */
declare const MapLibreGLOn: import("@ember/component/template-only").TemplateOnlyComponent<never> & (abstract new () => import("@glint/template/-private/integration").InvokableInstance<(named: import("@glint/template/-private/integration").NamedArgs<Args>) => import("@glint/template/-private/integration").ComponentReturn<import("@glint/template/-private/integration").FlattenBlockParams<{}>, unknown>> & import("@glint/template/-private/integration").HasContext<import("@glint/ember-tsc/types").ComponentContext<null, Args>>);
export default MapLibreGLOn;
//# sourceMappingURL=maplibre-gl-on.d.ts.map