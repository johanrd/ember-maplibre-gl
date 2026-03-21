# MapLibreGL

The main map component. Creates a MapLibre GL JS map instance and yields sub-components for composing map content.

## Import

```ts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
```

## Error Handling

The component supports an `error` named block. The yielded value is an `Error` object with a `.message` property:

```hbs
<MapLibreGL @initOptions={{this.options}}>
  <:default as |map|>
    <!-- map content -->
  </:default>
  <:error as |error|>
    <p>Map failed to load: {{error.message}}</p>
  </:error>
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

<!-- SIGNATURE -->
## Signature

```ts
interface MapLibreGLSignature {
    Element: HTMLDivElement;
    Args: {
        /**
         * MapLibre map options (style, center, zoom, etc.). Passed once at construction; later changes are ignored.
         * The `container` property is managed internally and should be omitted.
         *
         * @see https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/
         */
        initOptions: Omit<MapOptions, 'container'>;
        /** Called once the map's style and tiles have loaded. Receives the map instance. */
        mapLoaded?: (map: MaplibreMap) => void;
        /**
         * Cache the WebGL map instance on teardown and reuse it on remount.
         * Avoids expensive context creation on repeated route transitions.
         * Only works when `initOptions.style` is a URL string.
         */
        reuseMaps?: boolean;
        /** Override the map constructor (e.g. for testing or mapbox-gl compatibility). */
        mapLib?: new (...args: unknown[]) => MaplibreMap;
    };
    Blocks: {
        /**
         * Yields an object with pre-bound child components and the map instance.
         * Available after the map has loaded.
         */
        default: [
            {
                /** Invoke a method on the map instance declaratively. */
                call: WithBoundArgs<typeof MapLibreGLCall, 'obj'>;
                /** Add a UI control (navigation, scale, etc.) to the map. */
                control: WithBoundArgs<typeof MapLibreGLControl, 'map' | 'parent'>;
                /** Load and register a custom image for use in symbol layers. */
                image: WithBoundArgs<typeof MapLibreGLImage, 'map' | 'parent'>;
                /** Add a rendering layer directly (without an explicit source component). */
                layer: WithBoundArgs<typeof MapLibreGLLayer, 'map' | 'parent'>;
                /** Place a draggable marker on the map. */
                marker: WithBoundArgs<typeof MapLibreGLMarker, 'map' | 'parent'>;
                /** Bind an event listener to the map. */
                on: WithBoundArgs<typeof MapLibreGLOn, 'eventSource'>;
                /** Show a popup overlay on the map. */
                popup: WithBoundArgs<typeof MapLibreGLPopup, 'map'>;
                /** Add a data source (GeoJSON, vector tiles, etc.) to the map. */
                source: WithBoundArgs<typeof MapLibreGLSource, 'map' | 'parent'>;
                /** The underlying MapLibre map instance (always defined inside the default block). */
                instance: MaplibreMap | undefined;
                /** The Ember component instance (useful for associateDestroyableChild). */
                component: MapLibreGL;
            }
        ];
        /** Yielded when the map encounters a fatal error (e.g. WebGL context lost). Receives an `Error` with a `.message` property. */
        error: [Error];
    };
}
```
<!-- /SIGNATURE -->

<!-- ARGS -->
## Args

| Arg | Type | Required | Description |
|-----|------|----------|-------------|
| `initOptions` | Omit<[MapOptions](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/), 'container'> | Yes | MapLibre map options (style, center, zoom, etc.). Passed once at construction; later changes are ignored. The `container` property is managed internally and should be omitted. |
| `mapLoaded` | `Function` | No | Called once the map's style and tiles have loaded. Receives the map instance. |
| `reuseMaps` | `boolean` | No | Cache the WebGL map instance on teardown and reuse it on remount. Avoids expensive context creation on repeated route transitions. Only works when `initOptions.style` is a URL string. |
| `mapLib` | `MapConstructor` | No | Override the map constructor (e.g. for testing or mapbox-gl compatibility). |

<!-- /ARGS -->

<!-- YIELDS -->
## Yields

| Property | Type | Description |
|----------|------|-------------|
| `call` | [MapLibreGLCall](./call) | Invoke a method on the map instance declaratively. |
| `control` | [MapLibreGLControl](./control) | Add a UI control (navigation, scale, etc.) to the map. |
| `image` | [MapLibreGLImage](./image) | Load and register a custom image for use in symbol layers. |
| `layer` | [MapLibreGLLayer](./layer) | Add a rendering layer directly (without an explicit source component). |
| `marker` | [MapLibreGLMarker](./marker) | Place a draggable marker on the map. |
| `on` | [MapLibreGLOn](./on) | Bind an event listener to the map. |
| `popup` | [MapLibreGLPopup](./popup) | Show a popup overlay on the map. |
| `source` | [MapLibreGLSource](./source) | Add a data source (GeoJSON, vector tiles, etc.) to the map. |
| `instance` | `MaplibreMap | undefined` | The underlying MapLibre map instance (always defined inside the default block). |
| `component` | `MapLibreGL` | The Ember component instance (useful for associateDestroyableChild). |

<!-- /YIELDS -->

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
