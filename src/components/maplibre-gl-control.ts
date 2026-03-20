import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type MapLibreGL from './maplibre-gl.gts';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';

export interface MapLibreGLControlArgs {
  map: maplibregl.Map;
  control: maplibregl.IControl;
  position: Parameters<maplibregl.Map['addControl']>['1'];
  parent?: MapLibreGL;
}

export interface MapLibreGLControlSignature {
  Args: MapLibreGLControlArgs;
}

export default class MapLibreGLControl extends Component<MapLibreGLControlSignature> {
  @tracked control: MapLibreGLControlArgs['control'] | undefined;

  constructor(owner: Owner, args: MapLibreGLControlArgs) {
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
