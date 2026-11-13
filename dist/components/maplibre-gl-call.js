import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/**
 * Public function method surface of the MapLibre [Map ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/).
 *
 * Excludes `_`-prefixed internals and non-method properties so `@func` only
 * auto-completes callable public methods.
 */
/** Signature for {@link MapLibreGLCall}. */
/**
 * Declaratively invokes a method on the map instance.
 *
 * The method runs again on each revalidation in which consumed tracked state
 * changed, even when the argument values are the same. Glimmer propagates by
 * tag, not by value, so `(array)` and `(hash)` build a new object after any
 * upstream change. A stable reference does not prevent this, and neither does
 * `@cached`.
 *
 * A repeat call restarts an animation. For `fitBounds`, `flyTo` and `easeTo`,
 * keep the last arguments. If they do not change, return early.
 *
 * @access `<MapLibreGL>` as `map.call`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.call @func="flyTo" @positionalArguments={{array (hash center=this.target zoom=14)}} />
 * </MapLibreGL>
 * ```
 */
class MapLibreGLCall extends Component {
  /** @internal */get onResp() {
    return this.args.onResp || (() => {});
  }
  /** @internal */
  call = (obj, func, positionalArguments) => {
    assert('maplibre-gl-call obj is required', typeof obj === 'object' && !!obj);
    assert('maplibre-gl-call func is required and must be a string', typeof func === 'string');
    assert(`maplibre-gl-call ${String(func)} must be a function on the provided object`, typeof obj[func] === 'function');
    const method = obj[func];
    this.onResp?.(method.apply(obj, positionalArguments));
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.call @obj @func @positionalArguments}}", {
      strictMode: true
    }), this);
  }
}

export { MapLibreGLCall as default };
//# sourceMappingURL=maplibre-gl-call.js.map
