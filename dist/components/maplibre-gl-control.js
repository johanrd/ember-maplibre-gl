import { associateDestroyableChild, registerDestructor } from '@ember/destroyable';
import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { hash } from '@ember/helper';
import MapLibreGLOn from './maplibre-gl-on.js';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/** Signature for {@link MapLibreGLControl}. */
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
class MapLibreGLControl extends Component {
  /** @internal */_currentControl;
  _currentPosition;
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLControl` component', args.map);
    assert('`control` argument is required for `MapLibreGLControl` component', args.control);
    const {
      control,
      position,
      map
    } = args;
    this._currentControl = control;
    this._currentPosition = position;
    map.addControl(control, position);
    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this._currentControl) this.args.map?.removeControl(this._currentControl);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }
  /** @internal */
  updateControl = (control, position) => {
    if (control === this._currentControl && position === this._currentPosition) return;
    if (this._currentControl) {
      try {
        this.args.map.removeControl(this._currentControl);
      } catch {
        // Map may be in a broken state
      }
    }
    this._currentControl = control;
    this._currentPosition = position;
    this.args.map.addControl(control, position);
  };
  /** @internal */
  get eventSource() {
    const ctrl = this._currentControl;
    return ctrl && 'on' in ctrl ? ctrl : undefined;
  }
  static {
    setComponentTemplate(precompileTemplate("{{this.updateControl @control @position}}\n{{yield (hash on=(component MapLibreGLOn eventSource=this.eventSource))}}", {
      strictMode: true,
      scope: () => ({
        hash,
        MapLibreGLOn
      })
    }), this);
  }
}

export { MapLibreGLControl as default };
//# sourceMappingURL=maplibre-gl-control.js.map
