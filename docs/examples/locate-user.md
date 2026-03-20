# Locate the User

Track the user's location on the map using MapLibre's built-in `GeolocateControl`.

```gts live preview
import { hash, array } from '@ember/helper';
import { GeolocateControl } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const geolocate = new GeolocateControl({
  positionOptions: { enableHighAccuracy: true },
  trackUserLocation: true,
});

<template>
  <MapLibreGL
    @initOptions={{hash style="https://tiles.openfreemap.org/styles/liberty" center=(array -96 37.8) zoom=3}}
    style="height: 500px; width: 100%; border-radius: 8px;"
  as |map|>
    <map.control @control={{geolocate}} @position="top-right" />
  </MapLibreGL>
</template>
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/locate-the-user/">Locate the user</a> example.</p>
