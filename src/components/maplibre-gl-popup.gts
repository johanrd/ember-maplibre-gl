import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { Marker, Popup, type PopupOptions, type LngLatLike } from 'maplibre-gl';
import MapLibreGLOn from './maplibre-gl-on.gts';
import type { WithBoundArgs } from '@glint/template';
import { hash } from '@ember/helper';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import type maplibregl from 'maplibre-gl';

// todo: add support for maplibre-gl popups
export interface MapLibreGLPopupArgs {
  map: maplibregl.Map;
  marker?: Marker;
  lngLat?: LngLatLike;
  initOptions?: PopupOptions;
}
export interface MapLibreGLPopupSignature {
  Args: MapLibreGLPopupArgs;
  Blocks: {
    default: [
      {
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
      },
    ];
  };
}

export default class MapLibreGLPopup extends Component<MapLibreGLPopupSignature> {
  @tracked popup?: Popup;
  @tracked domContent = document.createElement('div');

  constructor(owner: Owner, args: MapLibreGLPopupArgs) {
    super(owner, args);

    const { initOptions, marker, map, lngLat } = args;

    const options = {
      ...initOptions,
    };

    this.popup = new Popup(options).setDOMContent(this.domContent);

    if (marker === undefined) {
      this.popup.addTo(map);
      if (lngLat) this.popup.setLngLat(lngLat);
    } else {
      marker.setPopup(this.popup);
    }

    registerDestructor(this, () => {
      try {
        if (marker) marker.setPopup(undefined);
        this.popup?.remove();
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  updatePopupLngLat = (lngLat: MapLibreGLPopupArgs['lngLat']) => {
    if (lngLat) {
      if (this.popup?.isOpen()) {
        this.popup?.setLngLat(lngLat);
      } else {
        this.popup?.remove();
        this.popup?.addTo(this.args.map);
        this.popup?.setLngLat(lngLat);
      }
    }
  };

  <template>
    {{this.updatePopupLngLat @lngLat}}
    {{#in-element this.domContent}}
      {{yield (hash on=(component MapLibreGLOn eventSource=this.popup))}}
    {{/in-element}}
  </template>
}
