import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';

/**
 * User-facing types that represents the minimal intersection between Mapbox.Map and Maplibre.Map
 * User provided `mapLib.Map` is supposed to implement this interface
 * Only losely typed for compatibility
 * inspired by https://github.com/visgl/react-map-gl/blob/master/src/types/lib.ts#L26
 */

interface Evented {
  on: maplibregl.Map['on'];
  off: maplibregl.Map['off'];
  once: maplibregl.Map['once'];
}

export interface MapInstance extends Evented {
  fire: maplibregl.Map['fire'];
  addControl: maplibregl.Map['addControl'];
  flyTo: maplibregl.Map['flyTo'];
  removeControl: maplibregl.Map['removeControl'];
  hasControl: maplibregl.Map['hasControl'];
  resize: maplibregl.Map['resize'];
  queryRenderedFeatures: maplibregl.Map['queryRenderedFeatures'];
  setStyle: maplibregl.Map['setStyle'];
  isMoving: maplibregl.Map['isMoving'];
  getStyle: maplibregl.Map['getStyle'];
  getZoom: maplibregl.Map['getZoom'];
  isStyleLoaded: maplibregl.Map['isStyleLoaded'];
  addSource: maplibregl.Map['addSource'];
  removeSource: maplibregl.Map['removeSource'];
  getSource: maplibregl.Map['getSource'];
  addLayer: maplibregl.Map['addLayer'];
  moveLayer: maplibregl.Map['moveLayer'];
  removeLayer: maplibregl.Map['removeLayer'];
  getLayer: maplibregl.Map['getLayer'];
  setFilter: maplibregl.Map['setFilter'];
  setLayerZoomRange: maplibregl.Map['setLayerZoomRange'];
  setPaintProperty: maplibregl.Map['setPaintProperty'];
  setLayoutProperty: maplibregl.Map['setLayoutProperty'];
  project: maplibregl.Map['project'];
  unproject: maplibregl.Map['unproject'];
  queryTerrainElevation?: maplibregl.Map['queryTerrainElevation'];
  getContainer: maplibregl.Map['getContainer'];
  getCanvas: maplibregl.Map['getCanvas'];
  remove: maplibregl.Map['remove'];
  triggerRepaint: maplibregl.Map['triggerRepaint'];
  setPadding: maplibregl.Map['setPadding'];
  fitBounds: maplibregl.Map['fitBounds'];
  //setFog?: T extends maplibregl.Map ? maplibregl.Map['setFog'] : undefined
  setLight?: maplibregl.Map['setLight'];
  setTerrain?: maplibregl.Map['setTerrain'];
}

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
  constructor(owner: Owner, args: MapLibreGLCallSignature['Args']) {
    super(owner, args);
    this.call(args.obj, args.func, args.positionalArguments);
  }

  /** @internal */
  call = (
    obj: MapInstance,
    func: keyof MapInstance,
    positionalArguments: unknown[],
  ) => {
    assert(
      `maplibre-gl-call ${String(func)} must be a function on the provided object`,
      typeof obj[func] === 'function',
    );

    assert(
      'maplibre-gl-call obj is required',
      typeof obj === 'object' && !!obj,
    );
    assert(
      'maplibre-gl-call func is required and must be a string',
      typeof func === 'string',
    );

    const method = obj[func] as (...args: unknown[]) => unknown;
    return this.onResp?.(method.apply(obj, positionalArguments));
  };

  <template>{{this.call @obj @func @positionalArguments}}</template>
}
