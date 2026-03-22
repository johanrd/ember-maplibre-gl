# Marker

<!-- DESCRIPTION -->
Places a marker on the map at a given position. The block content becomes the
marker's DOM element, so you can render any Ember template inside it.
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.marker @lngLat={{array -96.79 32.77}} @initOptions={{hash draggable=true}} as |marker|>
    <marker.popup>
      <p>Hello from Dallas!</p>
    </marker.popup>
    <marker.on @event="dragend" @action={{this.onDragEnd}} />
  </map.marker>
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.marker` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLMarker from 'ember-maplibre-gl/components/maplibre-gl-marker';
```
:::
<!-- /IMPORT -->

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLMarkerSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** Geographic position of the marker. Reactively updates when changed. */
        lngLat: LngLatLike;
        /** Marker configuration passed once at construction (draggable, color, anchor, etc.). */
        initOptions?: MarkerOptions;
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
    Blocks: {
        /** Yields a pre-bound `popup` (attached to this marker) and `on` for marker events (e.g. dragend). */
        default: [
            {
                /** Attach a popup to this marker. Pre-bound with map and marker reference. */
                popup: WithBoundArgs<typeof MapLibreGLPopup, 'map' | 'marker'>;
                /** Listen to marker events (drag, dragstart, dragend). Pre-bound with eventSource. */
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
| `lngLat` | [LngLatLike](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/LngLatLike/) | Yes | Geographic position of the marker. Reactively updates when changed. |
| `initOptions` | [MarkerOptions](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MarkerOptions/) | No | Marker configuration passed once at construction (draggable, color, anchor, etc.). |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `popup` | [MapLibreGLPopup](./popup) | Attach a popup to this marker. Pre-bound with map and marker reference. |
| `on` | [MapLibreGLOn](./on) | Listen to marker events (drag, dragstart, dragend). Pre-bound with eventSource. |

<!-- /YIELDS -->

## Demo

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { array, hash } from '@ember/helper';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-74.006, 40.7128],
  zoom: 11,
};

<template>
  <MapLibreGL @initOptions={{options}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.marker @lngLat={{array -74.006 40.7128}} as |marker|>
      <div style="font-size: 28px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));">📍</div>
      <marker.popup @initOptions={{hash offset=20 closeButton=false}}>
        <div style="padding: 8px 12px; font-family: system-ui;">
          <strong>New York City</strong>
          <p style="margin: 4px 0 0; color: #666;">Custom marker with popup</p>
        </div>
      </marker.popup>
    </map.marker>
  </MapLibreGL>
</template>
```
