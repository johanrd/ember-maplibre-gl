# Control

<!-- DESCRIPTION -->
Adds a UI control to the map (navigation, scale, attribution, geolocation, etc.).
The control is removed when the component is destroyed. Reactively updates
when `@control` or `@position` changes.
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.control @control={{this.navControl}} @position="top-right" />
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.control` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLControl from 'ember-maplibre-gl/components/maplibre-gl-control';
```
:::
<!-- /IMPORT -->

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLControlSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** A MapLibre IControl instance. Controls that extend Evented (e.g. `GeolocateControl`) support event binding via the yielded `on` component. */
        control: IControl;
        /** Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". */
        position: Parameters<maplibregl.Map['addControl']>['1'];
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
    Blocks: {
        /** Yields an `on` component for listening to control events (e.g. geolocate). */
        default: [
            {
                /** Listen to control events. Pre-bound with eventSource. Only works for controls that extend Evented. */
                on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
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
| `control` | [IControl](https://maplibre.org/maplibre-gl-js/docs/API/interfaces/IControl/) | Yes | A MapLibre IControl instance. Controls that extend Evented (e.g. `GeolocateControl`) support event binding via the yielded `on` component. |
| `position` | `ControlPosition` | Yes | Corner placement: "top-left", "top-right", "bottom-left", or "bottom-right". |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `on` | [MapLibreGLOn](./on) | Listen to control events. Pre-bound with eventSource. Only works for controls that extend Evented. |

<!-- /YIELDS -->

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
