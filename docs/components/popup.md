# Popup

<!-- DESCRIPTION -->
Displays a popup overlay on the map. Can be attached to a marker or positioned
standalone at a coordinate. The block content becomes the popup's DOM.
<!-- /DESCRIPTION -->

<!-- EXAMPLE -->
## Example

```gts
<MapLibreGL @initOptions={{this.mapOptions}} as |map|>
  <map.popup @lngLat={{array -96.79 32.77}} @initOptions={{hash closeButton=false}} as |popup|>
    <p>Standalone popup content</p>
    <popup.on @event="close" @action={{this.onPopupClose}} />
  </map.popup>
</MapLibreGL>
```
<!-- /EXAMPLE -->

<!-- IMPORT -->
## Import

Yielded by `<MapLibreGL>` as `map.popup`, or `<map.marker>` as `marker.popup` — no import needed.

::: details Direct import (rare)
```ts
import MapLibreGLPopup from 'ember-maplibre-gl/components/maplibre-gl-popup';
```
:::
<!-- /IMPORT -->

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLPopupSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** Marker to attach this popup to. When set, the popup opens on marker interaction. */
        marker?: Marker;
        /** Geographic position for standalone popups (not attached to a marker). Reactively updates. Note: changing `lngLat` will reopen a user-closed popup. */
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
| `lngLat` | [LngLatLike](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/LngLatLike/) | No | Geographic position for standalone popups (not attached to a marker). Reactively updates. Note: changing `lngLat` will reopen a user-closed popup. |
| `initOptions` | [PopupOptions](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/PopupOptions/) | No | Popup configuration passed once at construction (closeButton, closeOnClick, anchor, offset, etc.). |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `on` | [MapLibreGLOn](./on) | Listen to popup events (open, close). Pre-bound with eventSource. |

<!-- /YIELDS -->

## Demo

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { array, hash } from '@ember/helper';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-96.8, 32.8],
  zoom: 10,
};

<template>
  <MapLibreGL @initOptions={{options}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
    <map.popup @lngLat={{array -96.8 32.8}} @initOptions={{hash focusAfterOpen=false}}>
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
