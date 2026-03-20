# Installation

## Install the addon

```bash
pnpm add ember-maplibre-gl
```

## Import MapLibre CSS

MapLibre GL JS requires its CSS to be loaded. Import it in your app's CSS:

```css
@import 'maplibre-gl/dist/maplibre-gl.css';
```

## Usage

```gts
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const options = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-74.5, 40],
  zoom: 9,
};

<template>
  <MapLibreGL @initOptions={{options}} style="height: 400px; width: 100%;" />
</template>
```

::: details Glint registry for loose-mode (.hbs) templates
If you're using `.hbs` templates with Glint, augment the template registry:

```typescript
// types/glint.d.ts
import type EmberMapLibreGLRegistry from 'ember-maplibre-gl/template-registry';

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry extends EmberMapLibreGLRegistry {}
}
```
:::
