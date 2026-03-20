# GeoJSON Source

Display GeoJSON data with data-driven circle styling. Zoom in to see individual points grow, colored by magnitude.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-98, 39],
  zoom: 3,
};

const source = {
  type: 'geojson',
  data: {
    type: 'FeatureCollection',
    features: [
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.42, 37.78] }, properties: { name: 'San Francisco', pop: 874000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-73.94, 40.67] }, properties: { name: 'New York', pop: 8336000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-87.63, 41.88] }, properties: { name: 'Chicago', pop: 2697000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-118.24, 34.05] }, properties: { name: 'Los Angeles', pop: 3979000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-95.37, 29.76] }, properties: { name: 'Houston', pop: 2304000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-112.07, 33.45] }, properties: { name: 'Phoenix', pop: 1681000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-75.17, 39.95] }, properties: { name: 'Philadelphia', pop: 1603000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-98.49, 29.42] }, properties: { name: 'San Antonio', pop: 1547000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-96.80, 32.78] }, properties: { name: 'Dallas', pop: 1344000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-121.89, 37.34] }, properties: { name: 'San Jose', pop: 1027000 } },
    ],
  },
};

const circleLayer = {
  type: 'circle',
  paint: {
    'circle-radius': [
      'interpolate', ['linear'], ['get', 'pop'],
      500000, 6,
      2000000, 14,
      8000000, 28,
    ],
    'circle-color': [
      'interpolate', ['linear'], ['get', 'pop'],
      500000, '#2DC4B2',
      2000000, '#3BB3C3',
      5000000, '#669EC4',
      8000000, '#8B88B6',
    ],
    'circle-opacity': 0.8,
    'circle-stroke-color': '#ffffff',
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

<template>
  <MapLibreGL
    @initOptions={{mapOptions}}
    style="height: 400px; width: 100%; border-radius: 8px;"
  as |map|>
    <map.source @options={{source}} as |source|>
      <source.layer @options={{circleLayer}} />
      <source.layer @options={{labelLayer}} />
    </map.source>
  </MapLibreGL>
</template>
```
