# Reuse Maps

By default, navigating away from a route destroys the map instance and recreates it when the user navigates back. This causes a visible reload — tiles are re-fetched, the style is re-parsed, and there is a flash of empty canvas.

The `@reuseMaps` arg tells the component to **cache the map instance** instead of destroying it. When the component remounts with the same options, the cached map is re-attached to the DOM instantly — no reload, no flicker.

## Usage

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const options = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [12.5, 41.88],
  zoom: 5,
};

<template>
  <MapLibreGL
    @initOptions={{options}}
    @reuseMaps={{true}}
    style="height: 400px; width: 100%;"
  />
</template>
```

## When to use it

- **Multi-tab or wizard UIs** where the user switches between a map view and other views
- **Route transitions** where the same map appears on multiple routes (e.g. a sidebar map)
- **Dashboards** with conditional rendering that toggles the map on and off

## How it works

When `@reuseMaps` is `true` and the component is torn down, the map canvas is detached from the DOM but kept in memory. The next `<MapLibreGL>` component that mounts with `@reuseMaps={{true}}` re-attaches the cached map. The map retains its viewport, loaded tiles, and all state — making transitions feel seamless.

::: tip
Combine `@reuseMaps` with route-level `model` hooks to avoid unnecessary data refetching alongside the instant map restore.
:::
