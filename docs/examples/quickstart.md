# Quick Start

## Basic Map

Render a map with MapLibre's free demo tiles:

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

<template>
  <MapLibreGL
    @initOptions={{hash
      style="https://demotiles.maplibre.org/style.json"
      center=(array -74.5 40)
      zoom=9
    }}
    style="height: 400px; width: 100%;"
  />
</template>
```

## Adding Data

Use `<map.source>` and `<source.layer>` to display data:

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const geojson = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      geometry: { type: 'Point', coordinates: [-74.5, 40] },
      properties: { name: 'New York Area' },
    },
  ],
};

<template>
  <MapLibreGL
    @initOptions={{hash
      style="https://demotiles.maplibre.org/style.json"
      center=(array -74.5 40)
      zoom=9
    }}
    style="height: 400px; width: 100%;"
  as |map|>
    <map.source @options={{hash type="geojson" data=geojson}} as |source|>
      <source.layer @options={{hash
        type="circle"
        paint=(hash circle-color="#007cbf" circle-radius=10)
      }} />
    </map.source>
  </MapLibreGL>
</template>
```

## Responding to Events

Use `<map.on>` to handle map events:

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const handleClick = (e) => {
  console.log('Map clicked at:', e.lngLat);
};

<template>
  <MapLibreGL
    @initOptions={{hash
      style="https://demotiles.maplibre.org/style.json"
      center=(array -74.5 40)
      zoom=9
    }}
    style="height: 400px; width: 100%;"
  as |map|>
    <map.on @event="click" @action={{handleClick}} />
  </MapLibreGL>
</template>
```
