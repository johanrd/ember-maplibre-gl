import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { Marker } from 'maplibre-gl';
import MapLibreGLOn from './maplibre-gl-on.js';
import MapLibreGLPopup from './maplibre-gl-popup.js';
import { hash } from '@ember/helper';
import { associateDestroyableChild, registerDestructor } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/**
 * Places a marker on the map at a given position. The block content becomes the
 * marker's DOM element, so you can render any Ember template inside it.
 *
 * @access `<MapLibreGL>` as `map.marker`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.marker @lngLat={{array -96.79 32.77}} @initOptions={{hash draggable=true}} as |marker|>
 *     <marker.popup>
 *       <p>Hello from Dallas!</p>
 *     </marker.popup>
 *     <marker.on @event="dragend" @action={{this.onDragEnd}} />
 *   </map.marker>
 * </MapLibreGL>
 * ```
 */
class MapLibreGLMarker extends Component {
  /** @internal */marker;
  /** @internal */
  domContent = document.createElement('div');
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLMarker` component', args.map);
    assert('`lngLat` argument is required for `MapLibreGLMarker` component', args.lngLat);
    this.marker = new Marker(this.markerOptions).setLngLat(args.lngLat).addTo(args.map);
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
  get markerOptions() {
    return {
      ...this.args.initOptions,
      element: this.domContent
    };
  }
  _prevLngLat;
  /** @internal */
  updateMarker = lngLat => {
    assert('`lngLat` argument is required for `MapLibreGLMarker` component', lngLat);
    if (lngLat === this._prevLngLat) return;
    this._prevLngLat = lngLat;
    this.marker?.setLngLat(lngLat);
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.updateMarker @lngLat}}\n{{#in-element this.domContent}}\n  {{yield (hash popup=(component MapLibreGLPopup map=@map marker=this.marker) on=(component MapLibreGLOn eventSource=this.marker))}}\n{{/in-element}}", {
      strictMode: true,
      scope: () => ({
        hash,
        MapLibreGLPopup,
        MapLibreGLOn
      })
    }), this);
  }
}

export { MapLibreGLMarker as default };
//# sourceMappingURL=maplibre-gl-marker.js.map
