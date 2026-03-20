# Basic Map

A simple map using [OpenFreeMap](https://openfreemap.org/) tiles — no API key required.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [12.5, 41.88],
  zoom: 5,
};

<template>
  <MapLibreGL
    @initOptions={{options}}
    style="height: 400px; width: 100%; border-radius: 8px;"
  />
</template>
```
