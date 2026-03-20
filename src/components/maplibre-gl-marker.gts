import Component from '@glimmer/component';
import { assert } from '@ember/debug';

import { Marker, type MarkerOptions, type LngLatLike } from 'maplibre-gl';

import MapLibreGLOn from './maplibre-gl-on.gts';
import MapLibreGLPopup from './maplibre-gl-popup.gts';
import type MapLibreGL from './maplibre-gl.gts';
import type { WithBoundArgs } from '@glint/template';
import { hash } from '@ember/helper';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import type Owner from '@ember/owner';
import type maplibregl from 'maplibre-gl';

export interface MapLibreGLMarkerArgs {
  map: maplibregl.Map;
  lngLat: LngLatLike;
  initOptions?: MarkerOptions;
  parent?: MapLibreGL;
}
export interface MapLibreGLMarkerSignature {
  Args: MapLibreGLMarkerArgs;
  Blocks: {
    default: [
      {
        popup: WithBoundArgs<typeof MapLibreGLPopup, 'map' | 'marker'>;
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
      },
    ];
  };
}

export default class MapLibreGLMarker extends Component<MapLibreGLMarkerSignature> {
  marker: Marker | undefined;
  domContent = document.createElement('div');

  constructor(owner: Owner, args: MapLibreGLMarkerArgs) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLMarker` component',
      args.map,
    );
    assert(
      '`lngLat` argument is required for `MapLibreGLMarker` component',
      args.lngLat,
    );

    this.marker = new Marker(this.markerOptions)
      .setLngLat(args.lngLat)
      .addTo(args.map);

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        this.marker?.remove();
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  get markerOptions(): MarkerOptions {
    return {
      ...this.args.initOptions,
      element: this.domContent,
    };
  }

  updateMarker = (lngLat: LngLatLike) => {
    assert(
      '`lngLat` argument is required for `MapLibreGLMarker` component',
      lngLat,
    );

    this.marker?.setLngLat(lngLat);
  };

  <template>
    {{this.updateMarker @lngLat}}
    {{#in-element this.domContent}}
      {{yield
        (hash
          popup=(component MapLibreGLPopup map=@map marker=this.marker)
          on=(component MapLibreGLOn eventSource=this.marker)
        )
      }}
    {{/in-element}}
  </template>
}
