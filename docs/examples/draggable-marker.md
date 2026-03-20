# Draggable Marker

Drag the marker to a new location and see its coordinates update.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { Marker } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-74.006, 40.7128],
  zoom: 12,
};

const markerOptions = { draggable: true };

export default class DraggableMarkerDemo extends Component {
  @tracked lng = -74.006;
  @tracked lat = 40.7128;

  get lngLat() {
    return [this.lng, this.lat];
  }

  onDragEnd = (event: { target: Marker }) => {
    const lngLat = event.target.getLngLat();
    this.lng = lngLat.lng;
    this.lat = lngLat.lat;
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        <map.marker @lngLat={{this.lngLat}} @initOptions={{markerOptions}} as |marker|>
          <div style="
            width: 24px; height: 24px;
            background: #E04E39;
            border: 3px solid white;
            border-radius: 50%;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            cursor: grab;
          " />
          <marker.on @event="dragend" @action={{this.onDragEnd}} />
        </map.marker>
      </MapLibreGL>
      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 8px 12px; border-radius: 6px; font: 13px/1.4 monospace;">
        Lng: {{this.lng}}<br />Lat: {{this.lat}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/create-a-draggable-marker/">Create a draggable marker</a> example.</p>
