import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { Popup } from 'maplibre-gl';
import MapLibreGLOn from './maplibre-gl-on.js';
import { hash } from '@ember/helper';
import { registerDestructor } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

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
class MapLibreGLPopup extends Component {
  /** @internal */popup;
  /** @internal */
  domContent = document.createElement('div');
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLPopup` component', args.map);
    const {
      initOptions,
      marker,
      map,
      lngLat
    } = args;
    const options = {
      ...initOptions
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
  updatePopupLngLat = lngLat => {
    if (lngLat) {
      this.popup?.setLngLat(lngLat);
      if (!this.popup?.isOpen()) {
        this.popup?.addTo(this.args.map);
      }
    }
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.updatePopupLngLat @lngLat}}\n{{#in-element this.domContent}}\n  {{yield (hash on=(component MapLibreGLOn eventSource=this.popup))}}\n{{/in-element}}", {
      strictMode: true,
      scope: () => ({
        hash,
        MapLibreGLOn
      })
    }), this);
  }
}

export { MapLibreGLPopup as default };
//# sourceMappingURL=maplibre-gl-popup.js.map
