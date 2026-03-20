# Interactive Features

Click a city to show a popup with details. Demonstrates layer-specific events, reactive state with `@tracked`, and standalone popups.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { MapMouseEvent, MapGeoJSONFeature } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { NavigationControl } from 'maplibre-gl';

const nav = new NavigationControl();

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-98, 39],
  zoom: 3.5,
};

const source = {
  type: 'geojson',
  data: {
    type: 'FeatureCollection',
    features: [
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.42, 37.78] }, properties: { name: 'San Francisco', state: 'California', pop: '874K' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-73.94, 40.67] }, properties: { name: 'New York', state: 'New York', pop: '8.3M' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-87.63, 41.88] }, properties: { name: 'Chicago', state: 'Illinois', pop: '2.7M' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-118.24, 34.05] }, properties: { name: 'Los Angeles', state: 'California', pop: '4.0M' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-95.37, 29.76] }, properties: { name: 'Houston', state: 'Texas', pop: '2.3M' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-104.99, 39.74] }, properties: { name: 'Denver', state: 'Colorado', pop: '716K' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-90.07, 29.95] }, properties: { name: 'New Orleans', state: 'Louisiana', pop: '383K' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-71.06, 42.36] }, properties: { name: 'Boston', state: 'Massachusetts', pop: '675K' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.33, 47.61] }, properties: { name: 'Seattle', state: 'Washington', pop: '737K' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-80.19, 25.76] }, properties: { name: 'Miami', state: 'Florida', pop: '442K' } },
    ],
  },
};

const circleLayer = {
  id: 'cities',
  type: 'circle',
  paint: {
    'circle-radius': 8,
    'circle-color': '#4264fb',
    'circle-stroke-color': '#fff',
    'circle-stroke-width': 2,
  },
};

const labelLayer = {
  type: 'symbol',
  layout: {
    'text-field': ['get', 'name'],
    'text-size': 12,
    'text-offset': [0, 1.5],
    'text-anchor': 'top',
  },
  paint: {
    'text-color': '#333',
    'text-halo-color': '#fff',
    'text-halo-width': 1.5,
  },
};

export default class InteractiveDemo extends Component {
  @tracked popupLngLat: [number, number] | null = null;
  @tracked popupName = '';
  @tracked popupState = '';
  @tracked popupPop = '';

  onCityClick = (e: MapMouseEvent & { features?: MapGeoJSONFeature[] }) => {
    const feature = e.features?.[0];
    if (!feature) return;
    this.popupLngLat = feature.geometry.coordinates.slice();
    this.popupName = feature.properties.name;
    this.popupState = feature.properties.state;
    this.popupPop = feature.properties.pop;
  };

  <template>
    <MapLibreGL
      @initOptions={{mapOptions}}
      style="height: 500px; width: 100%; border-radius: 8px;"
    as |map|>
      <map.control @control={{nav}} @position="top-right" />
      <map.source @options={{source}} as |source|>
        <source.layer @options={{circleLayer}} />
        <source.layer @options={{labelLayer}} />
      </map.source>
      <map.on @event="click" @layerId="cities" @action={{this.onCityClick}} />
      {{#if this.popupLngLat}}
        <map.popup @lngLat={{this.popupLngLat}}>
          <div style="padding: 8px 12px; font-family: system-ui;">
            <strong style="font-size: 15px;">{{this.popupName}}</strong>
            <div style="color: #666; margin-top: 4px;">{{this.popupState}}</div>
            <div style="margin-top: 4px;">Population: <strong>{{this.popupPop}}</strong></div>
          </div>
        </map.popup>
      {{/if}}
    </MapLibreGL>
  </template>
}
```
