# Source

<!-- DESCRIPTION -->
Adds a data source to the map. Sources provide the data that layers render.
Supports GeoJSON, vector tiles, raster, image, and video source types.

Updates to `@options` are applied reactively (e.g. setData for GeoJSON).
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.source @options={{this.geojsonSource}} as |source|>
    <source.layer @options={{this.circleLayer}} />
  </map.source>
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.source` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLSource from 'ember-maplibre-gl/components/maplibre-gl-source';
```
:::
<!-- /IMPORT -->

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
