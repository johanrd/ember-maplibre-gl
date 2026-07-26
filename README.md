# ember-maplibre-gl

Declarative [MapLibre GL JS](https://maplibre.org/maplibre-gl-js/docs/) components for [Ember.js](https://emberjs.com/).

[Demo and docs](https://johanrd.github.io/ember-maplibre-gl)

## Installation

```bash
pnpm add ember-maplibre-gl
```

Import the MapLibre CSS in your app:

```css
@import 'maplibre-gl/dist/maplibre-gl.css';
```

### MapLibre v6+: configure the worker

MapLibre v6 ships as ESM with a separate worker file that bundlers can't
resolve automatically, so each app must point MapLibre at the worker once at
startup. The right incantation depends on your bundler — this addon
deliberately leaves it to the app. With Vite (Embroider + Vite), add to your
`app.ts`:

```ts
import { setWorkerUrl } from 'maplibre-gl';
import maplibreWorkerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';

setWorkerUrl(maplibreWorkerUrl);
```

See the [MapLibre installation docs](https://maplibre.org/maplibre-gl-js/docs/)
for webpack and other bundlers, and the
[v5 → v6 migration guide](https://maplibre.org/maplibre-gl-js/docs/guides/v5-to-v6-migration-guide/)
for the other v6 changes. MapLibre v5 needs no worker setup.

## Usage

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

<template>
  <MapLibreGL 
    @initOptions={{hash style="https://demotiles.maplibre.org/style.json" center=(array -74.5 40) zoom=9 }} 
  as |map|>
    <map.source @options={{hash type="geojson" data=this.geojson}} as |source|>
      <source.layer @options={{hash type="circle" paint=(hash circle-color="#007cbf" circle-radius=8)}} />
    </map.source>
    <map.marker @lngLat={{array -74.5 40}} as |marker|>
      <marker.popup>Hello!</marker.popup>
    </map.marker>
    <map.on @event="click" @action={{this.handleClick}} />
  </MapLibreGL>
</template>
```

## Components

| Component | Description |
|-----------|-------------|
| `<MapLibreGL>` | Main map container, yields all sub-components |
| `<map.source>` | Add data sources (GeoJSON, vector, raster) |
| `<source.layer>` | Style and render source data |
| `<map.marker>` | Place markers with custom Ember content |
| `<map.popup>` | Standalone or marker-attached popups |
| `<map.on>` | Declarative event handling |
| `<map.control>` | Add map controls |
| `<map.image>` | Load images for symbol layers |
| `<map.call>` | Call map methods imperatively |


## Compatibility
- Ember.js v3.28 or above
- Embroider v2 addon
- MapLibre GL JS v5 and above (for v6+, configure the worker — see
  [Installation](#maplibre-v6-configure-the-worker) and the
  [v5 → v6 migration guide](https://maplibre.org/maplibre-gl-js/docs/guides/v5-to-v6-migration-guide/))


## Acknowledgements

This project is derived from [ember-mapbox-gl](https://github.com/kturney/ember-mapbox-gl) by [Kyle Turney](https://github.com/kturney) and contributors, rewritten for [MapLibre GL JS](https://maplibre.org/) and modern Ember (Glimmer components, template-tag `.gts`, Embroider v2).

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

## License

This project is licensed under the [MIT License](LICENSE.md).
