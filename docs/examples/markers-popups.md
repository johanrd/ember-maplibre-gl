# Markers & Popups

Place custom markers at world landmarks with rich popup content.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { array, hash } from '@ember/helper';

const cities = [
  { name: 'Paris',     emoji: '🗼', lngLat: [2.3522, 48.8566],   desc: 'City of Light' },
  { name: 'Tokyo',     emoji: '🏯', lngLat: [139.6917, 35.6895], desc: 'Where tradition meets future' },
  { name: 'New York',  emoji: '🗽', lngLat: [-74.006, 40.7128],  desc: 'The city that never sleeps' },
  { name: 'Sydney',    emoji: '🏖️', lngLat: [151.2093, -33.8688], desc: 'Harbour city' },
  { name: 'Cairo',     emoji: '🏛️', lngLat: [31.2357, 30.0444],  desc: 'Gateway to ancient wonders' },
  { name: 'Rio',       emoji: '🎭', lngLat: [-43.1729, -22.9068], desc: 'Cidade Maravilhosa' },
];

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [20, 20],
  zoom: 1.5,
};

<template>
  <MapLibreGL
    @initOptions={{options}}
    style="height: 500px; width: 100%; border-radius: 8px;"
  as |map|>
    {{#each cities as |city|}}
      <map.marker @lngLat={{city.lngLat}} as |marker|>
        <div style="
          font-size: 28px;
          cursor: pointer;
          filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
        ">{{city.emoji}}</div>
        <marker.popup @initOptions={{hash offset=20}}>
          <div style="padding: 8px 12px; font-family: system-ui;">
            <strong style="font-size: 16px;">{{city.name}}</strong>
            <p style="margin: 4px 0 0; color: #666;">{{city.desc}}</p>
          </div>
        </marker.popup>
      </map.marker>
    {{/each}}
  </MapLibreGL>
</template>
```
