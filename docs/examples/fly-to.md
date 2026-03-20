# Fly To

Smoothly animate the camera between world cities using MapLibre's `flyTo` method.

```gts live preview
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const cities = [
  { name: 'New York',  center: [-74.006, 40.7128],    zoom: 14, pitch: 50, bearing: -20 },
  { name: 'London',    center: [-0.1276, 51.5074],    zoom: 14, pitch: 45, bearing: 10 },
  { name: 'Tokyo',     center: [139.7525, 35.6852],   zoom: 14, pitch: 50, bearing: -30 },
  { name: 'Cape Town', center: [18.4241, -33.9249],   zoom: 13, pitch: 40, bearing: 0 },
  { name: 'Rio',       center: [-43.1729, -22.9068],  zoom: 13, pitch: 50, bearing: 40 },
];

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [0, 20],
  zoom: 2,
};

interface City {
  name: string;
  center: [number, number];
  zoom: number;
  pitch: number;
  bearing: number;
}

export default class FlyToDemo extends Component {
  flyTo = (map: Map, city: City) => {
    map.flyTo({
      center: city.center,
      zoom: city.zoom,
      pitch: city.pitch,
      bearing: city.bearing,
      duration: 3000,
      essential: true,
    });
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        <div style="
          position: absolute; top: 12px; left: 12px; z-index: 1;
          display: flex; gap: 6px; flex-wrap: wrap;
        ">
          {{#each cities as |city|}}
            <button
              {{on "click" (fn this.flyTo map.instance city)}}
              style="
                padding: 6px 14px;
                background: #fff;
                border: 1px solid #ddd;
                border-radius: 6px;
                font: 13px/1 system-ui;
                cursor: pointer;
                box-shadow: 0 1px 3px rgba(0,0,0,0.15);
              "
            >{{city.name}}</button>
          {{/each}}
        </div>
      </MapLibreGL>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/fly-to-a-location/">Fly to</a> example.</p>
