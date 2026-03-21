# Popup

Displays a popup on the map, either standalone at coordinates or attached to a marker.

## Usage

This component is yielded by `<MapLibreGL>` and `<map.marker>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  {{! Standalone popup }}
  <map.popup @lngLat={{lngLat}}>Content</map.popup>

  {{! Marker-attached popup }}
  <map.marker @lngLat={{lngLat}} as |marker|>
    <marker.popup>Content</marker.popup>
  </map.marker>
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLPopup from 'ember-maplibre-gl/components/maplibre-gl-popup';
```
:::

## Standalone Popup

```hbs
<map.popup @lngLat={{array -96.8 32.8}}>
  <h3>Dallas, TX</h3>
</map.popup>
```

## Marker Popup

```hbs
<map.marker @lngLat={{array -96.8 32.8}} as |marker|>
  <marker.popup>
    <p>Click the marker to see this!</p>
  </marker.popup>
</map.marker>
```

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLPopupSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** Marker to attach this popup to. When set, the popup opens on marker interaction. */
        marker?: Marker;
        /** Geographic position for standalone popups (not attached to a marker). Reactively updates. */
        lngLat?: LngLatLike;
        /** Popup configuration passed once at construction (closeButton, closeOnClick, anchor, offset, etc.). */
        initOptions?: PopupOptions;
    };
    Blocks: {
        /** Yields an `on` component for listening to popup events (open, close). Block content becomes the popup DOM. */
        default: [
            {
                /** Listen to popup events (open, close). Pre-bound with eventSource. */
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
| `marker` | `Marker` | No | Marker to attach this popup to. When set, the popup opens on marker interaction. |
| `lngLat` | [LngLatLike](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/LngLatLike/) | No | Geographic position for standalone popups (not attached to a marker). Reactively updates. |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `on` | `MapLibreGLOn` | Listen to popup events (open, close). Pre-bound with eventSource. |

<!-- /YIELDS -->

## Demo

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { array } from '@ember/helper';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-96.8, 32.8],
  zoom: 10,
};

<template>
  <MapLibreGL @initOptions={{options}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.popup @lngLat={{array -96.8 32.8}}>
      <div style="padding: 8px 12px; font-family: system-ui;">
        <strong>Dallas, TX</strong>
        <p style="margin: 4px 0 0; color: #666;">A standalone popup at coordinates</p>
      </div>
    </map.popup>
    <map.marker @lngLat={{array -97.1 32.95}} as |marker|>
      <div style="font-size: 24px;">📌</div>
      <marker.popup>
        <div style="padding: 8px 12px; font-family: system-ui;">
          <strong>Fort Worth</strong>
          <p style="margin: 4px 0 0; color: #666;">Popup attached to a marker</p>
        </div>
      </marker.popup>
    </map.marker>
  </MapLibreGL>
</template>
```
