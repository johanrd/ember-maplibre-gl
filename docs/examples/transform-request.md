# Authorized Tile Sources

Some tile providers require authentication — an API key in a header, a signed URL, or a token query parameter. MapLibre's `transformRequest` option lets you intercept every network request the map makes and modify it before it is sent.

## How it works

Pass a `transformRequest` function in `initOptions`. MapLibre calls it for every resource (tiles, sprites, glyphs, style JSON) with the URL and resource type. Return an object with the modified `url` and optional `headers`.

## Example: API key header

```ts
// app/utils/transform-request.ts
import type { RequestTransformFunction } from 'maplibre-gl';

const transformRequest: RequestTransformFunction = function (url, resourceType) {
  if (url.startsWith('https://tiles.example.com')) {
    return {
      url,
      headers: { 'Authorization': `Bearer ${MY_API_KEY}` },
    };
  }
  return { url };
};

export default transformRequest;
```

## Example: token query parameter

```ts
// app/utils/transform-request.ts
import type { RequestTransformFunction } from 'maplibre-gl';

const transformRequest: RequestTransformFunction = function (url, resourceType) {
  if (url.startsWith('https://tiles.example.com')) {
    const separator = url.includes('?') ? '&' : '?';
    return { url: `${url}${separator}access_token=${MY_TOKEN}` };
  }
  return { url };
};

export default transformRequest;
```

::: tip
`transformRequest` is called for **every** network request the map makes. Keep the function fast and use early `return { url }` for URLs that don't need modification.
:::

## Usage in a template

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { hash } from '@ember/helper';
import transformRequest from 'your-app/utils/transform-request';

<template>
  <MapLibreGL
    @initOptions={{hash
      style="https://tiles.example.com/style.json"
      center=(array 11 63)
      zoom=5
      transformRequest=transformRequest
    }}
    style="height: 400px; width: 100%;"
  />
</template>
```
