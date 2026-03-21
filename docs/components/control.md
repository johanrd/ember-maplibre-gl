# Control

Adds a UI control to the map (navigation, scale, fullscreen, etc.).

## Usage

This component is yielded by `<MapLibreGL>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.control ... />
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLControl from 'ember-maplibre-gl/components/maplibre-gl-control';
```
:::

## Example

```gts
import { NavigationControl } from 'maplibre-gl';

const nav = new NavigationControl();

<template>
  <map.control @control={{nav}} @position="top-right" />
</template>
```

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLControlSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** A MapLibre IControl instance (e.g. `new NavigationControl()`, `new ScaleControl()`). */
        control: maplibregl.IControl;
        /** Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". */
        position: Parameters<maplibregl.Map['addControl']>['1'];
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
| `control` | [IControl](https://maplibre.org/maplibre-gl-js/docs/API/interfaces/IControl/) | Yes | A MapLibre IControl instance (e.g. `new NavigationControl()`, `new ScaleControl()`). |
| `position` | `ControlPosition` | Yes | Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". |

<!-- /ARGS -->

## Demo

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { NavigationControl, ScaleControl } from 'maplibre-gl';

const nav = new NavigationControl({ visualizePitch: true });
const scale = new ScaleControl();

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [2.35, 48.86],
  zoom: 12,
  pitch: 45,
};

<template>
  <MapLibreGL @initOptions={{options}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.control @control={{nav}} @position="top-right" />
    <map.control @control={{scale}} @position="bottom-left" />
  </MapLibreGL>
</template>
```
