import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import type MapLibreGL from './maplibre-gl.gts';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';

/** Signature for {@link MapLibreGLControl}. */
export interface MapLibreGLControlSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: maplibregl.Map;
    /** A MapLibre IControl instance (e.g. `new NavigationControl()`, `new ScaleControl()`). */
    control: maplibregl.IControl;
    /** Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". */
    position: Parameters<maplibregl.Map['addControl']>['1'];
    /** Parent component for destroyable association (pre-bound by parent). */
    parent?: MapLibreGL;
  };
}

/**
 * Adds a UI control to the map (navigation, scale, attribution, geolocation, etc.).
 * The control is removed when the component is destroyed. Reactively updates
 * when `@control` or `@position` changes.
 *
 * Yielded by `<MapLibreGL>` as `map.control`. Does not yield any block content.
 *
 * @example
 * ```gts
 * import { NavigationControl } from 'maplibre-gl';
 *
 * <map.control @control={{this.navControl}} @position="top-right" />
 * ```
 */
export default class MapLibreGLControl extends Component<MapLibreGLControlSignature> {
  /** @internal */
  private _currentControl?: maplibregl.IControl;
  private _currentPosition?: MapLibreGLControlSignature['Args']['position'];

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLControlSignature['Args']) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLControl` component',
      args.map,
    );
    assert(
      '`control` argument is required for `MapLibreGLControl` component',
      args.control,
    );

    const { control, position, map } = args;
    this._currentControl = control;
    this._currentPosition = position;
    map.addControl(control, position);

    if (args.parent) associateDestroyableChild(args.parent, this);

    registerDestructor(this, () => {
      try {
        if (this._currentControl)
          this.args.map?.removeControl(this._currentControl);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  /** @internal */
  updateControl = (
    control: maplibregl.IControl,
    position: MapLibreGLControlSignature['Args']['position'],
  ) => {
    if (
      control === this._currentControl &&
      position === this._currentPosition
    )
      return;

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

  <template>{{this.updateControl @control @position}}</template>
}
