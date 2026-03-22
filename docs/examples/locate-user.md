# Locate the User

Track the user's location on the map using MapLibre's built-in `GeolocateControl`. The `<map.control>` component yields an `on` component for listening to control events like `geolocate`.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import { GeolocateControl } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const geolocate = new GeolocateControl({
  positionOptions: { enableHighAccuracy: true },
  trackUserLocation: true,
});

export default class LocateUserDemo extends Component {
  @tracked coords = 'Click the locate button ↗';

  onGeolocate = (e: GeolocationPosition) => {
    const { longitude, latitude } = e.coords;
    this.coords = `${latitude.toFixed(4)}°, ${longitude.toFixed(4)}°`;
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{hash style="https://tiles.openfreemap.org/styles/liberty" center=(array -96 37.8) zoom=3}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        <map.control @control={{geolocate}} @position="top-right" as |control|>
          <control.on @event="geolocate" @action={{this.onGeolocate}} />
        </map.control>
      </MapLibreGL>
      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 8px 12px; border-radius: 6px; font: 13px/1.4 monospace;">
        {{this.coords}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/locate-the-user/">Locate the user</a> example.</p>
