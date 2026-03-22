import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { Marker, Popup, type PopupOptions, type LngLatLike } from 'maplibre-gl';
import MapLibreGLOn from './maplibre-gl-on.gts';
import type { WithBoundArgs } from '@glint/template';
import { hash } from '@ember/helper';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import type maplibregl from 'maplibre-gl';

/** Signature for {@link MapLibreGLPopup}. */
export interface MapLibreGLPopupSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: maplibregl.Map;
    /** Marker to attach this popup to. When set, the popup opens on marker interaction. */
    marker?: Marker;
    /** Geographic position for standalone popups (not attached to a marker). Reactively updates. Note: changing `lngLat` will reopen a user-closed popup. */
    lngLat?: LngLatLike;
    /** Popup configuration passed once at construction (closeButton, closeOnClick, anchor, offset, etc.). */
    initOptions?: PopupOptions;
  };
  Blocks: {
    /** Yields an `on` component for listening to popup events (open, close). Block content becomes the popup DOM. */
    default: [
      {
        /** Listen to popup events (open, close). Pre-bound with eventSource. */
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
      },
    ];
  };
}

/**
 * Displays a popup overlay on the map. Can be attached to a marker or positioned
 * standalone at a coordinate. The block content becomes the popup's DOM.
 *
 * @access `<MapLibreGL>` as `map.popup`, or `<map.marker>` as `marker.popup`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.popup @lngLat={{array -96.79 32.77}} @initOptions={{hash closeButton=false}} as |popup|>
 *     <p>Standalone popup content</p>
 *     <popup.on @event="close" @action={{this.onPopupClose}} />
 *   </map.popup>
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLPopup extends Component<MapLibreGLPopupSignature> {
  /** @internal */
  popup?: Popup;
  /** @internal */
  domContent = document.createElement('div');

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLPopupSignature['Args']) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLPopup` component',
      args.map,
    );

    const { initOptions, marker, map, lngLat } = args;

    const options = {
      ...initOptions,
    };

    this.popup = new Popup(options).setDOMContent(this.domContent);

    if (marker === undefined) {
      if (lngLat) this.popup.setLngLat(lngLat);
      this.popup.addTo(map);
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

  /** @internal */
  updatePopupLngLat = (lngLat: MapLibreGLPopupSignature['Args']['lngLat']) => {
    if (lngLat) {
      if (this.popup?.isOpen()) {
        this.popup?.setLngLat(lngLat);
      } else {
        this.popup?.setLngLat(lngLat);
        this.popup?.addTo(this.args.map);
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
