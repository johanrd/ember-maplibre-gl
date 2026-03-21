# Using Mapbox Styles

MapLibre GL JS can render Mapbox-hosted styles using [maplibregl-mapbox-request-transformer](https://github.com/rowanwins/maplibregl-mapbox-request-transformer) to rewrite `mapbox://` URLs.

```gts live preview
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { isMapboxURL, transformMapboxUrl } from 'maplibregl-mapbox-request-transformer';

// Demo token — restricted to johanrd.github.io/ember-maplibre-gl. Get your own at https://account.mapbox.com/access-tokens/
const MAPBOX_TOKEN = 'pk.eyJ1Ijoiam9oYW5yb2VkIiwiYSI6ImNtbjBza25nejBuaTQycHM5YzlvYWczNWoifQ.0bCPJQRbhHxsSEO32l2RrA';

const transformRequest = (url: string, resourceType?: string) => {
  if (isMapboxURL(url)) {
    return transformMapboxUrl(url, resourceType ?? '', MAPBOX_TOKEN);
  }
  return { url };
};

const mapOptions = {
  style: 'mapbox://styles/mapbox/outdoors-v11',
  center: [10.75, 59.91] as [number, number],
  zoom: 9.1,
  transformRequest,
};

<template>
  <MapLibreGL
    @initOptions={{mapOptions}}
    style="height: 500px; width: 100%; border-radius: 8px;"
  />
</template>
```

::: tip
You need a valid [Mapbox access token](https://account.mapbox.com/access-tokens/). Public tokens (`pk.`) are safe to use client-side — restrict them to your domain in the Mapbox dashboard.
:::
