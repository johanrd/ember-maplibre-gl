# Marker

Places a marker on the map at specified coordinates. Supports custom Ember content as the marker element.

## Usage

This component is yielded by `<MapLibreGL>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.marker ... />
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLMarker from 'ember-maplibre-gl/components/maplibre-gl-marker';
```
:::

## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `map` | `Map` | Yes | Map instance (auto-bound). |
| `lngLat` | `LngLatLike` | Yes | Marker coordinates `[lng, lat]`. |
| `initOptions` | `MarkerOptions` | No | MapLibre marker options (color, draggable, etc.). |

## Yields

| Property | Type | Description |
|----------|------|-------------|
| `popup` | `MapLibreGLPopup` | Add a popup to this marker. |
| `on` | `MapLibreGLOn` | Bind marker events (drag, click, etc.). |

## Custom Content

Block content is rendered inside the marker element:

```hbs
<map.marker @lngLat={{array -74.5 40}} as |marker|>
  <div class="custom-marker">
    <img src="/pin.svg" alt="marker" />
  </div>
  <marker.popup>
    <p>Hello from New York!</p>
  </marker.popup>
</map.marker>
```

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
