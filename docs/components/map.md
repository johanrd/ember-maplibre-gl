# MapLibreGL

The main map component. Creates a MapLibre GL JS map instance and yields sub-components for composing map content.

## Import

```ts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
```

## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `initOptions` | `MapOptions` | Yes | MapLibre map options (`style`, `center`, `zoom`, etc.). Only used during construction. |
| `mapLoaded` | `(map: Map) => void` | No | Callback fired when the map finishes loading. |
| `reuseMaps` | `boolean` | No | Cache and reuse the map instance across route transitions. |
| `mapLib` | `MapConstructor` | No | Custom map constructor (defaults to `maplibregl.Map`). See [Custom Map Constructor](#custom-map-constructor). |

## Yields

| Property | Type | Description |
|----------|------|-------------|
| `source` | `MapLibreGLSource` | Add data sources (pre-bound with `map`). |
| `layer` | `MapLibreGLLayer` | Add standalone layers (pre-bound with `map`). |
| `marker` | `MapLibreGLMarker` | Add markers (pre-bound with `map`). |
| `popup` | `MapLibreGLPopup` | Add popups (pre-bound with `map`). |
| `on` | `MapLibreGLOn` | Bind map events (pre-bound with `eventSource`). |
| `control` | `MapLibreGLControl` | Add controls (pre-bound with `map`). |
| `image` | `MapLibreGLImage` | Load images (pre-bound with `map`). |
| `call` | `MapLibreGLCall` | Call map methods (pre-bound with `obj`). |
| `instance` | `Map \| undefined` | The raw MapLibre GL map instance. |

## Error Handling

The component supports an `error` named block:

```hbs
<MapLibreGL @initOptions={{this.options}} as |map|>
  <!-- map content -->
{{else error as |error|}}
  <p>Map failed to load: {{error}}</p>
</MapLibreGL>
```

## Custom Map Constructor

The `@mapLib` arg lets you swap in a different map constructor. This is useful for:

- **Testing** — pass a mock/stub constructor to avoid WebGL in tests
- **Mapbox GL JS** — in theory, Mapbox's `Map` class could work since MapLibre forked from it, but API drift means this is not guaranteed
- **Custom subclasses** — extend `maplibregl.Map` with project-specific behavior

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { Map as CustomMap } from 'some-maplibre-fork';

const options = { style: '...', center: [0, 0], zoom: 2 };

<template>
  <MapLibreGL @initOptions={{options}} @mapLib={{CustomMap}} />
</template>
```

::: warning
The constructor must be API-compatible with `maplibregl.Map`. Passing an incompatible constructor will likely cause runtime errors in sub-components that call MapLibre-specific methods.
:::

## Demo

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
    style="height: 300px; width: 100%; border-radius: 8px;"
  />
</template>
```
