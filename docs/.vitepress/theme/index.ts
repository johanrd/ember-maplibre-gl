import DefaultTheme from 'vitepress/theme'
import { setupEmber } from 'vite-plugin-ember/setup'
import type { Theme } from 'vitepress'
import { setWorkerUrl } from 'maplibre-gl'
// MapLibre v6+ resolves its worker relative to import.meta.url, which no bundler
// can rewrite, so every consumer points it at the worker once. See the README.
import maplibreWorkerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url'
import 'maplibre-gl/dist/maplibre-gl.css'
import './custom.css'
import EmberCodePreview from './EmberCodePreview.vue'
import HomeLayout from './HomeLayout.vue'

setWorkerUrl(maplibreWorkerUrl)

export default {
  ...DefaultTheme,
  Layout: HomeLayout,
  enhanceApp({ app }) {
    setupEmber(app)
    app.component('CodePreview', EmberCodePreview)
  },
} satisfies Theme
