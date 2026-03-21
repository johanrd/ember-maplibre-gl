# Using Mapbox Styles

MapLibre GL JS is a fork of Mapbox GL JS, and can render Mapbox-hosted styles with the help of the [maplibregl-mapbox-request-transformer](https://github.com/rowanwins/maplibregl-mapbox-request-transformer) package. This rewrites `mapbox://` URLs to their actual tile endpoints with your access token.

## Setup

Install the request transformer:

```bash
pnpm add maplibregl-mapbox-request-transformer
```

## Create a transform helper

Create a utility that converts `mapbox://` URLs to authenticated requests:

```ts
// app/utils/transform-request.ts
import type { RequestTransformFunction } from 'maplibre-gl';
import {
  isMapboxURL,
  transformMapboxUrl,
} from 'maplibregl-mapbox-request-transformer';
import config from 'your-app/config/environment';

const transformRequest: RequestTransformFunction = function (
  url: string,
  resourceType?: string,
) {
  if (isMapboxURL(url) && resourceType !== undefined) {
    return transformMapboxUrl(
      url,
      resourceType,
      config['mapbox-gl'].accessToken,
    );
  }
  return { url };
};

export default transformRequest;
```

## Usage

Pass `transformRequest` as part of `initOptions` to use Mapbox styles:

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { hash } from '@ember/helper';
import transformRequest from 'your-app/utils/transform-request';

<template>
  <MapLibreGL
    @initOptions={{hash
      style="mapbox://styles/mapbox/outdoors-v11"
      center=(array 11 63)
      zoom=3
      transformRequest=transformRequest
    }}
    style="height: 400px; width: 100%;"
  />
</template>
```

::: warning
You need a valid [Mapbox access token](https://account.mapbox.com/access-tokens/). Store it in your app's environment config rather than hard-coding it.
:::

::: details Environment config example
```ts
// config/environment.js
module.exports = function (environment) {
  const ENV = {
    // ...
    'mapbox-gl': {
      accessToken: process.env.MAPBOX_ACCESS_TOKEN,
    },
  };
  return ENV;
};
```
:::
