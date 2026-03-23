# Call

<!-- DESCRIPTION -->
Declaratively invokes a method on the map instance. Re-invokes reactively
when `@func` or `@positionalArguments` reference changes — Glimmer's
`(array)`/`(hash)` helpers memoize references, so the method only fires
when inputs actually change.
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.call @func="flyTo" @positionalArguments={{array (hash center=this.target zoom=14)}} />
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.call` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLCall from 'ember-maplibre-gl/components/maplibre-gl-call';
```
:::
<!-- /IMPORT -->

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
| `func` | keyof [MapInstance](#mapinstance) | Yes | Name of the method to invoke (e.g. "flyTo", "setStyle", "resize"). |
| `positionalArguments` | unknown[] | Yes | Arguments to pass to the method. |
| `onResp` | `Function` | No | Optional callback that receives the method's return value. |

### MapInstance

Public function method surface of the MapLibre [Map ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/).
Excludes `_`-prefixed internals and non-method properties so `@func` only
auto-completes callable public methods.

```ts
type MapInstance = Pick<maplibregl.Map, PublicMethodKeys<maplibregl.Map>>
```

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
