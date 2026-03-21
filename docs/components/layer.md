# Layer

Adds a rendering layer to the map. Layers define how data from a source is styled and displayed.

## Usage

This component is yielded by `<map.source>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.source @options={{...}} as |source|>
    <source.layer ... />
  </map.source>
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLLayer from 'ember-maplibre-gl/components/maplibre-gl-layer';
```
:::

## Reactive Updates

When `@options` changes, the layer automatically updates its `paint`, `layout`, `filter`, and zoom range properties. Removed properties are reset to their defaults (following the react-map-gl pattern).

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLLayerSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** Source ID to render data from (pre-bound when used via `source.layer`). */
        sourceId: string;
        /** Layer specification (type, paint, layout, filter, etc.). The `id` and `source` are optional and auto-filled. */
        options: Omit<LayerSpecification, 'id'> & {
            id?: LayerSpecification['id'];
            source?: string;
        };
        /** Layer ID or position to insert this layer before in the stack. */
        before?: Parameters<maplibregl.Map['addLayer']>[1];
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGLSource | MapLibreGL;
    };
    Blocks: {
        /** Yields the layer's ID, useful for event binding or querying features. */
        default: [
            {
                /** The ID of this layer on the map. */
                id: string;
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
| `sourceId` | `string` | Yes | Source ID to render data from (pre-bound when used via `source.layer`). |
| `options` | [LayerSpecification](https://maplibre.org/maplibre-style-spec/layers/) | Yes | Layer specification (type, paint, layout, filter, etc.). The `id` and `source` are optional and auto-filled. |
| `before` | `string` | No | Layer ID or position to insert this layer before in the stack. |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `id` | `string` | The ID of this layer on the map. |

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
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-122.42, 37.78] }, properties: { pop: 874000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-73.94, 40.67] }, properties: { pop: 8336000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-87.63, 41.88] }, properties: { pop: 2697000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-118.24, 34.05] }, properties: { pop: 3979000 } },
      { type: 'Feature', geometry: { type: 'Point', coordinates: [-95.37, 29.76] }, properties: { pop: 2304000 } },
    ],
  },
};

const layer = {
  type: 'circle',
  paint: {
    'circle-radius': ['interpolate', ['linear'], ['get', 'pop'], 500000, 6, 8000000, 28],
    'circle-color': ['interpolate', ['linear'], ['get', 'pop'], 500000, '#2DC4B2', 8000000, '#8B88B6'],
    'circle-opacity': 0.8,
    'circle-stroke-color': '#fff',
    'circle-stroke-width': 2,
  },
};

<template>
  <MapLibreGL @initOptions={{mapOptions}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.source @options={{source}} as |source|>
      <source.layer @options={{layer}} />
    </map.source>
  </MapLibreGL>
</template>
```
