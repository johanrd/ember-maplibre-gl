import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
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
 * The control is removed when the component is destroyed.
 *
 * Yielded by `<MapLibreGL>` as `map.control`. Does not yield any block content.
 *
 * @example
 * ```gts
 * import { NavigationControl } from 'maplibre-gl';
 *
 * <map.control @control={{new NavigationControl}} @position="top-right" />
 * ```
 */
export default class MapLibreGLControl extends Component<MapLibreGLControlSignature> {
  /** @internal */
  @tracked control: MapLibreGLControlSignature['Args']['control'] | undefined;

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLControlSignature['Args']) {
    super(owner, args);

    const { control, position, map } = args;
    this.control = control;
    map.addControl(this.control, position);

    if (args.parent) associateDestroyableChild(args.parent, this);

    registerDestructor(this, () => {
      try {
        if (this.control) args.map?.removeControl(this.control);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }
}
