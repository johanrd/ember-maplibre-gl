# Introduction

`ember-maplibre-gl` provides Ember.js components for [MapLibre GL JS](https://maplibre.org/maplibre-gl-js/docs/), the open-source fork of Mapbox GL JS.

```gts live
import Component from '@glimmer/component';
import { hash, array } from '@ember/helper';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

export default class IntroDemo extends Component {
  onMapLoaded = (map: Map) => {
    setTimeout(() => {
      map.flyTo({
        center: [-74.006, 40.7128],
        zoom: 14,
        pitch: 60,
        bearing: -30,
        duration: 5000,
        essential: true,
      });
    }, 800);
  };

  <template>
    <MapLibreGL
      @initOptions={{hash
        style="https://tiles.openfreemap.org/styles/liberty"
        center=(array -95 40)
        zoom=2
      }}
      @mapLoaded={{this.onMapLoaded}}
      style="height: 400px; width: 100%; border-radius: 8px;"
    />
  </template>
}
```

## Features

- **`<MapLibreGL>`** — Main map container that yields all sub-components
- **`<map.source>`** — Add GeoJSON, vector, raster, and other data sources
- **`<source.layer>`** — Style data with circle, line, fill, symbol, and other layer types
- **`<map.marker>`** — Place markers with custom Ember content
- **`<map.popup>`** — Standalone or marker-attached popups
- **`<map.on>`** — Declarative event handling for map and layer events
- **`<map.control>`** — Add navigation, scale, and custom controls
- **`<map.image>`** — Load images and SVGs for use in symbol layers

## Architecture

The addon uses a composable, yielded-component pattern, inspired by [ember-mapbox-gl](https://github.com/kturney/ember-mapbox-gl). The main `<MapLibreGL>` component creates the map and yields pre-bound sub-components:

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

<template>
  <MapLibreGL
    @initOptions={{hash
      style="https://demotiles.maplibre.org/style.json"
      center=(array 0 20)
      zoom=1
    }}
  as |map|>
    <map.source @options={{hash type="geojson" data=this.geojson}} as |source|>
      <source.layer @options={{hash type="circle" paint=(hash circle-color="#ff0000")}} />
    </map.source>
  </MapLibreGL>
</template>
```
