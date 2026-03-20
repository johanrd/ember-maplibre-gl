# Heatmap

Visualize earthquake frequency using a heatmap that transitions to individual points as you zoom in. Data from [USGS](https://www.usgs.gov/programs/earthquake-hazards).

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { NavigationControl } from 'maplibre-gl';

const nav = new NavigationControl();

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-120, 50],
  zoom: 2,
};

const source = {
  type: 'geojson',
  data: 'https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson',
};

const heatmapLayer = {
  type: 'heatmap',
  maxzoom: 9,
  paint: {
    'heatmap-weight': ['interpolate', ['linear'], ['get', 'mag'], 0, 0, 6, 1],
    'heatmap-intensity': ['interpolate', ['linear'], ['zoom'], 0, 1, 9, 3],
    'heatmap-color': [
      'interpolate', ['linear'], ['heatmap-density'],
      0, 'rgba(33,102,172,0)',
      0.2, 'rgb(103,169,207)',
      0.4, 'rgb(209,229,240)',
      0.6, 'rgb(253,219,199)',
      0.8, 'rgb(239,138,98)',
      1, 'rgb(178,24,43)',
    ],
    'heatmap-radius': ['interpolate', ['linear'], ['zoom'], 0, 2, 9, 20],
    'heatmap-opacity': ['interpolate', ['linear'], ['zoom'], 7, 1, 9, 0],
  },
};

const pointLayer = {
  type: 'circle',
  minzoom: 7,
  paint: {
    'circle-radius': [
      'interpolate', ['linear'], ['zoom'],
      7, ['interpolate', ['linear'], ['get', 'mag'], 1, 1, 6, 4],
      16, ['interpolate', ['linear'], ['get', 'mag'], 1, 5, 6, 50],
    ],
    'circle-color': [
      'interpolate', ['linear'], ['get', 'mag'],
      1, 'rgba(33,102,172,0)',
      2, 'rgb(103,169,207)',
      3, 'rgb(209,229,240)',
      4, 'rgb(253,219,199)',
      5, 'rgb(239,138,98)',
      6, 'rgb(178,24,43)',
    ],
    'circle-stroke-color': '#fff',
    'circle-stroke-width': 1,
    'circle-opacity': ['interpolate', ['linear'], ['zoom'], 7, 0, 8, 1],
  },
};

<template>
  <MapLibreGL
    @initOptions={{mapOptions}}
    style="height: 500px; width: 100%; border-radius: 8px;"
  as |map|>
    <map.control @control={{nav}} @position="top-right" />
    <map.source @options={{source}} as |source|>
      <source.layer @options={{heatmapLayer}} />
      <source.layer @options={{pointLayer}} />
    </map.source>
  </MapLibreGL>
</template>
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/create-a-heatmap-layer/">Heatmap layer</a> example.</p>
