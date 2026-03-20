# Image

Loads an image or SVG for use in symbol layers.

## Usage

This component is yielded by `<MapLibreGL>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.image ... />
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLImage from 'ember-maplibre-gl/components/maplibre-gl-image';
```
:::

## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `map` | `Map` | Yes | Map instance (auto-bound). |
| `url` | `string` | Yes | Image URL (supports `.svg` and raster formats). |
| `name` | `string` | Yes | Unique image ID referenced in layer `icon-image`. |
| `options` | `object` | No | Image options (pixelRatio, sdf, etc.). |
| `width` | `number` | No | Width for SVG images. |
| `height` | `number` | No | Height for SVG images. |
| `onLoad` | `() => void` | No | Callback on successful load. |
| `onError` | `(err) => void` | No | Callback on load failure. |

## Example

```hbs
<map.image @name="marker-icon" @url="/assets/marker.png" />

<map.source @options={{hash type="geojson" data=this.points}} as |source|>
  <source.layer @options={{hash
    type="symbol"
    layout=(hash icon-image="marker-icon" icon-size=0.5)
  }} />
</map.source>
```

## Demo

Loads an SVG icon and renders it as symbols on a map layer.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-98, 39],
  zoom: 3,
};

const svgUrl = 'data:image/svg+xml,' + encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="%23e74c3c"/><circle cx="12" cy="12" r="4" fill="white"/></svg>'
);

const source = {
  type: 'geojson',
  data: {
    type: 'FeatureCollection',
    features: [
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.42, 37.78] }, properties: {} },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-73.94, 40.67] }, properties: {} },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-87.63, 41.88] }, properties: {} },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-118.24, 34.05] }, properties: {} },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-95.37, 29.76] }, properties: {} },
    ],
  },
};

const symbolLayer = {
  type: 'symbol',
  layout: { 'icon-image': 'target-icon', 'icon-size': 1.5, 'icon-allow-overlap': true },
};

<template>
  <MapLibreGL @initOptions={{mapOptions}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.image @name="target-icon" @url={{svgUrl}} @width={{24}} @height={{24}} />
    <map.source @options={{source}} as |source|>
      <source.layer @options={{symbolLayer}} />
    </map.source>
  </MapLibreGL>
</template>
```
