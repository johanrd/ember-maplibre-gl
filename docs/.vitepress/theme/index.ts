import DefaultTheme from 'vitepress/theme'
import { setupEmber } from 'vite-plugin-ember/setup'
import type { Theme } from 'vitepress'
import 'maplibre-gl/dist/maplibre-gl.css'
import './custom.css'
import EmberCodePreview from './EmberCodePreview.vue'
import HomeLayout from './HomeLayout.vue'

export default {
  ...DefaultTheme,
  Layout: HomeLayout,
  enhanceApp({ app }) {
    setupEmber(app)
    app.component('CodePreview', EmberCodePreview)
  },
} satisfies Theme
