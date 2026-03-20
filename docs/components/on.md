# On (Events)

Declaratively bind event handlers to the map, markers, popups, or specific layers.

## Usage

This component is yielded by `<MapLibreGL>`, `<map.marker>`, and `<map.popup>` — no import needed:

```hbs
<MapLibreGL @initOptions={{options}} as |map|>
  <map.on @event="click" @action={{handler}} />

  <map.marker @lngLat={{lngLat}} as |marker|>
    <marker.on @event="dragend" @action={{handler}} />
  </map.marker>
</MapLibreGL>
```

::: details Direct import (rare)
```ts
import MapLibreGLOn from 'ember-maplibre-gl/components/maplibre-gl-on';
```
:::

## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `event` | `string` | Yes | Event name (`'click'`, `'mousemove'`, `'zoom'`, etc.). |
| `action` | `Function` | Yes | Event handler callback. |
| `eventSource` | `Map \| Evented` | Yes | Object to listen on (auto-bound). |
| `layerId` | `string` | No | Target a specific layer's events. |

## Map Events

```hbs
<map.on @event="click" @action={{this.handleClick}} />
<map.on @event="zoom" @action={{this.handleZoom}} />
```

## Layer Events

```hbs
<source.layer @options={{hash type="circle"}} as |layer|>
  <map.on @event="click" @layerId={{layer.id}} @action={{this.onLayerClick}} />
  <map.on @event="mouseenter" @layerId={{layer.id}} @action={{this.onMouseEnter}} />
  <map.on @event="mouseleave" @layerId={{layer.id}} @action={{this.onMouseLeave}} />
</source.layer>
```

## Marker Events

```hbs
<map.marker @lngLat={{this.coords}} as |marker|>
  <marker.on @event="dragend" @action={{this.onDragEnd}} />
</map.marker>
```

## Demo

Click the map to log coordinates. Click a city circle to show an alert.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-98, 39],
  zoom: 3.5,
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

const layer = {
  id: 'cities-on-demo',
  type: 'circle',
  paint: { 'circle-radius': 10, 'circle-color': '#e74c3c', 'circle-stroke-color': '#fff', 'circle-stroke-width': 2 },
};

export default class OnDemo extends Component {
  @tracked lastClick = 'Click the map or a city...';

  onMapClick = (e: any) => {
    this.lastClick = `Map: ${e.lngLat.lng.toFixed(2)}, ${e.lngLat.lat.toFixed(2)}`;
  };

  onCityClick = (e: any) => {
    const name = e.features?.[0]?.properties?.name;
    if (name) this.lastClick = `City: ${name}`;
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL @initOptions={{mapOptions}} style="height: 300px; width: 100%; border-radius: 8px;" as |map|>
        <map.source @options={{source}} as |source|>
          <source.layer @options={{layer}} />
        </map.source>
        <map.on @event="click" @action={{this.onMapClick}} />
        <map.on @event="click" @layerId="cities-on-demo" @action={{this.onCityClick}} />
      </MapLibreGL>
      <div style="position: absolute; bottom: 12px; left: 12px; background: rgba(255,255,255,0.9); padding: 6px 12px; border-radius: 6px; font: 13px system-ui;">
        {{this.lastClick}}
      </div>
    </div>
  </template>
}
```
