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

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLSourceSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: Map;
        /** Custom source ID. Auto-generated if omitted. */
        sourceId?: string;
        /** Source specification matching MapLibre's `addSource` API (type, data, tiles, url, etc.). */
        options: Parameters<Map['addSource']>['1'];
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
    Blocks: {
        /** Yields the source ID and a pre-bound `layer` component scoped to this source. */
        default: [
            {
                /** The ID of this source on the map. */
                id: string;
                /** Add a layer that renders data from this source. Pre-bound with map, sourceId, and parent. */
                layer: WithBoundArgs<typeof MapLibreGLLayer, 'map' | 'sourceId' | 'parent'>;
            }
        ];
    };
}
```
<!-- /SIGNATURE -->

<!-- ARGS -->
## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `sourceId` | `string` | No | Custom source ID. Auto-generated if omitted. |
| `options` | [SourceSpecification](https://maplibre.org/maplibre-style-spec/sources/) | Yes | Source specification matching MapLibre's `addSource` API (type, data, tiles, url, etc.). |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | The ID of this source on the map. |
| `layer` | [MapLibreGLLayer](./layer) | Add a layer that renders data from this source. Pre-bound with map, sourceId, and parent. |

<!-- /YIELDS -->

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
