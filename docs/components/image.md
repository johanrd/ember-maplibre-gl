# Image

<!-- DESCRIPTION -->
Loads an image from a URL and registers it on the map for use in symbol layers.
Handles both raster (PNG/JPEG via `map.loadImage`) and SVG images (via `<img>`).
The image is removed from the map when the component is destroyed.
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.image @url="/icons/pin.png" @name="pin-icon" @onLoad={{this.onImageReady}} />
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.image` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLImage from 'ember-maplibre-gl/components/maplibre-gl-image';
```
:::
<!-- /IMPORT -->

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLImageSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** URL of the image to load. Supports PNG, JPEG, and SVG formats. */
        url?: Parameters<maplibregl.Map['loadImage']>['0'];
        /** Name to register the image under. Use this name in symbol layer `icon-image`. */
        name: Parameters<maplibregl.Map['addImage']>['0'];
        /** Image options (pixelRatio, sdf) passed to `map.addImage`. */
        options?: ImageOptions;
        /** Explicit width for SVG images (ignored for raster formats). */
        width?: HTMLImageElement['width'];
        /** Explicit height for SVG images (ignored for raster formats). */
        height?: HTMLImageElement['height'];
        /** Called when the image has been loaded and added to the map. */
        onLoad?: () => void;
        /** Called if the image fails to load. */
        onError?: (err: unknown) => void;
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
}
```
<!-- /SIGNATURE -->

<!-- ARGS -->
## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `url` | `string` | No | URL of the image to load. Supports PNG, JPEG, and SVG formats. |
| `name` | `string` | Yes | Name to register the image under. Use this name in symbol layer `icon-image`. |
| `options` | [ImageOptions](#imageoptions) | No | Image options (pixelRatio, sdf) passed to `map.addImage`. |
| `width` | `number` | No | Explicit width for SVG images (ignored for raster formats). |
| `height` | `number` | No | Explicit height for SVG images (ignored for raster formats). |
| `onLoad` | `Function` | No | Called when the image has been loaded and added to the map. |
| `onError` | `Function` | No | Called if the image fails to load. |

### ImageOptions

Options passed to MapLibre's [map.addImage ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/#addimage).
Supports `pixelRatio` (for HiDPI images) and `sdf` (to enable runtime recoloring).

```ts
type ImageOptions = Parameters<maplibregl.Map['addImage']>['2']
```

<!-- /ARGS -->
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
