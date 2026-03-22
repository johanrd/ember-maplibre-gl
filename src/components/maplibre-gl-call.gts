import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import type maplibregl from 'maplibre-gl';

/**
 * Callable method surface for `<map.call>`. Curated allow-list so `@func`
 * auto-completes only methods that make sense to invoke declaratively.
 * Types are derived from `maplibregl.Map` so they stay in sync automatically.
 *
 * Inspired by https://github.com/visgl/react-map-gl/blob/master/src/types/lib.ts#L26
 */
export type MapInstance = Pick<
  maplibregl.Map,
  | 'on'
  | 'off'
  | 'once'
  | 'fire'
  | 'addControl'
  | 'flyTo'
  | 'removeControl'
  | 'hasControl'
  | 'resize'
  | 'queryRenderedFeatures'
  | 'setStyle'
  | 'isMoving'
  | 'getStyle'
  | 'getZoom'
  | 'isStyleLoaded'
  | 'addSource'
  | 'removeSource'
  | 'getSource'
  | 'addLayer'
  | 'moveLayer'
  | 'removeLayer'
  | 'getLayer'
  | 'setFilter'
  | 'setLayerZoomRange'
  | 'setPaintProperty'
  | 'setLayoutProperty'
  | 'project'
  | 'unproject'
  | 'getContainer'
  | 'getCanvas'
  | 'remove'
  | 'triggerRepaint'
  | 'setPadding'
  | 'fitBounds'
  | 'queryTerrainElevation'
  | 'setLight'
  | 'setTerrain'
>;

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
 * Declaratively invokes a method on the map instance (or any object). Re-invokes
 * reactively when arguments change, making it useful for imperative map APIs
 * like `flyTo`, `setStyle`, or `resize` in a template-driven way.
 *
 * **Caution:** the method is called on every render. Guard with a conditional
 * to avoid repeated invocations (e.g. `flyTo` re-animating on unrelated state changes).
 *
 * Yielded by `<MapLibreGL>` as `map.call`. Does not yield any block content.
 *
 * @example
 * ```gts
 * <map.call @func="flyTo" @positionalArguments={{array (hash center=this.target zoom=14)}} />
 * <map.call @func="resize" @positionalArguments={{array}} />
 * ```
 */
export default class MapLibreGLCall extends Component<MapLibreGLCallSignature> {
  /** @internal */
  get onResp() {
    return this.args.onResp || (() => {});
  }

  /** @internal */
  call = (
    obj: MapInstance,
    func: keyof MapInstance,
    positionalArguments: unknown[],
  ) => {
    assert(
      'maplibre-gl-call obj is required',
      typeof obj === 'object' && !!obj,
    );
    assert(
      'maplibre-gl-call func is required and must be a string',
      typeof func === 'string',
    );
    assert(
      `maplibre-gl-call ${String(func)} must be a function on the provided object`,
      typeof obj[func] === 'function',
    );

    const method = obj[func] as (...args: unknown[]) => unknown;
    this.onResp?.(method.apply(obj, positionalArguments));
  };

  <template>{{this.call @obj @func @positionalArguments}}</template>
}
