# Source

Adds a data source to the map. Supports GeoJSON, vector tiles, raster tiles, and other [MapLibre source types](https://maplibre.org/maplibre-style-spec/sources/).

## Usage

This component is yielded by `<MapLibreGL>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.source ... />
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLSource from 'ember-maplibre-gl/components/maplibre-gl-source';
```
:::

## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `map` | `Map` | Yes | Map instance (auto-bound when used as `<map.source>`). |
| `options` | `SourceSpecification` | Yes | Source configuration (`type`, `data`, etc.). |
| `sourceId` | `string` | No | Custom source ID. Auto-generated if omitted. |

## Yields

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | The source ID. |
| `layer` | `MapLibreGLLayer` | Add layers for this source (pre-bound with `sourceId`). |

## Reactive Updates

When `@options` changes, the source is automatically updated:
- GeoJSON sources: calls `setData()`
- Image/video sources: calls `setCoordinates()`
- Vector/raster sources: calls `setUrl()` or `setTiles()`

## Example

```hbs
<map.source @options={{hash type="geojson" data=this.geojsonData}} as |source|>
  <source.layer @options={{hash
    type="circle"
    paint=(hash circle-color="#007cbf" circle-radius=8)
  }} />
</map.source>
```

## Demo

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
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.42, 37.78] }, properties: { name: 'San Francisco' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-73.94, 40.67] }, properties: { name: 'New York' } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-87.63, 41.88] }, properties: { name: 'Chicago' } },
    ],
  },
};

const circleLayer = {
  type: 'circle',
  paint: {
    'circle-radius': 8,
    'circle-color': '#007cbf',
    'circle-stroke-color': '#fff',
    'circle-stroke-width': 2,
  },
};

<template>
  <MapLibreGL @initOptions={{mapOptions}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.source @options={{source}} as |source|>
      <source.layer @options={{circleLayer}} />
    </map.source>
  </MapLibreGL>
</template>
```
