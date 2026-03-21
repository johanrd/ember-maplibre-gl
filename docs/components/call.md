# Call

Invokes a method on the map instance. Useful for imperative map operations like `flyTo`, `fitBounds`, etc.

## Usage

This component is yielded by `<MapLibreGL>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.call ... />
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLCall from 'ember-maplibre-gl/components/maplibre-gl-call';
```
:::

## Example

```hbs
<map.call
  @func="flyTo"
  @positionalArguments={{array (hash center=(array -74.5 40) zoom=12)}}
/>
```

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLCallSignature {
    Args: {
        /** The object to call the method on — typically the map instance (pre-bound by parent). */
        obj: MapInstance;
        /** Name of the method to invoke (e.g. "flyTo", "setStyle", "resize"). */
        func: keyof MapInstance;
        /** Arguments to pass to the method. */
        positionalArguments: unknown[];
        /** Optional callback that receives the method's return value. */
        onResp?: (result: unknown) => void;
    };
}
```
<!-- /SIGNATURE -->

<!-- ARGS -->
## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `func` | `keyof MapInstance` | Yes | Name of the method to invoke (e.g. "flyTo", "setStyle", "resize"). |
| `positionalArguments` | unknown[] | Yes | Arguments to pass to the method. |
| `onResp` | `Function` | No | Optional callback that receives the method's return value. |

<!-- /ARGS -->

## Demo

This map calls `fitBounds` on load to fit the view to a bounding box.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { array, hash } from '@ember/helper';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [0, 0],
  zoom: 1,
};

const bounds = [[-125, 24], [-66, 50]];

<template>
  <MapLibreGL @initOptions={{options}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.call @func="fitBounds" @positionalArguments={{array bounds (hash padding=40)}} />
  </MapLibreGL>
</template>
```
