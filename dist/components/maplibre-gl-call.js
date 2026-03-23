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
