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

/** Signature for {@link MapLibreGLMarker}. */
export interface MapLibreGLMarkerSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: maplibregl.Map;
    /** Geographic position of the marker. Reactively updates when changed. */
    lngLat: LngLatLike;
    /** Marker configuration passed once at construction (draggable, color, anchor, etc.). */
    initOptions?: MarkerOptions;
    /** Parent component for destroyable association (pre-bound by parent). */
    parent?: MapLibreGL;
  };
  Blocks: {
    /** Yields a pre-bound `popup` (attached to this marker) and `on` for marker events (e.g. dragend). */
    default: [
      {
        /** Attach a popup to this marker. Pre-bound with map and marker reference. */
        popup: WithBoundArgs<typeof MapLibreGLPopup, 'map' | 'marker'>;
        /** Listen to marker events (drag, dragstart, dragend). Pre-bound with eventSource. */
        on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
      },
    ];
  };
}

/**
 * Places a marker on the map at a given position. The block content becomes the
 * marker's DOM element, so you can render any Ember template inside it.
 *
 * Yielded by `<MapLibreGL>` as `map.marker`. Yields a pre-bound `popup` and `on` component.
 *
 * @example
 * ```gts
 * <map.marker @lngLat={{array -96.79 32.77}} @initOptions={{hash draggable=true}} as |marker|>
 *   <marker.popup>
 *     <p>Hello from Dallas!</p>
 *   </marker.popup>
 *   <marker.on @event="dragend" @action={{this.onDragEnd}} />
 * </map.marker>
 * ```
 */
export default class MapLibreGLMarker extends Component<MapLibreGLMarkerSignature> {
  /** @internal */
  marker: Marker | undefined;
  /** @internal */
  domContent = document.createElement('div');

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLMarkerSignature['Args']) {
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

  /** @internal */
  get markerOptions(): MarkerOptions {
    return {
      ...this.args.initOptions,
      element: this.domContent,
    };
  }

  /** @internal */
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
