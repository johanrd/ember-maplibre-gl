# 3D Terrain

Real 3D elevation using MapLibre's terrain rendering with free [OpenStreetMap](https://www.openstreetmap.org/) raster tiles and [MapLibre demo terrain](https://demotiles.maplibre.org/). Drag to orbit, scroll to zoom.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { NavigationControl } from 'maplibre-gl';

const nav = new NavigationControl({ visualizePitch: true });

const mapOptions = {
  zoom: 12,
  center: [11.39085, 47.27574],
  pitch: 70,
  bearing: -20,
  maxPitch: 85,
  style: {
    version: 8,
    sources: {
      osm: {
        type: 'raster',
        tiles: ['https://a.tile.openstreetmap.org/{z}/{x}/{y}.png'],
        tileSize: 256,
        attribution: '&copy; OpenStreetMap Contributors',
        maxzoom: 19,
      },
      terrain: {
        type: 'raster-dem',
        url: 'https://demotiles.maplibre.org/terrain-tiles/tiles.json',
        tileSize: 256,
      },
      hillshade: {
        type: 'raster-dem',
        url: 'https://demotiles.maplibre.org/terrain-tiles/tiles.json',
        tileSize: 256,
      },
    },
    layers: [
      { id: 'osm', type: 'raster', source: 'osm' },
      {
        id: 'hillshade',
        type: 'hillshade',
        source: 'hillshade',
        paint: { 'hillshade-shadow-color': '#473B24' },
      },
    ],
    terrain: { source: 'terrain', exaggeration: 1 },
    sky: {},
  },
};

<template>
  <MapLibreGL
    @initOptions={{mapOptions}}
    style="height: 500px; width: 100%; border-radius: 8px;"
  as |map|>
    <map.control @control={{nav}} @position="top-right" />
  </MapLibreGL>
</template>
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/3d-terrain/">3D Terrain</a> example.</p>
