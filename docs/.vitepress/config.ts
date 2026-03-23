import { defineConfig, type Plugin } from 'vitepress'
import vitePluginEmber, { emberFence } from 'vite-plugin-ember'
import typedocSidebarRaw from '../api/typedoc-sidebar.json'

const typedocSidebar = typedocSidebarRaw.map((group: any) => ({
  ...group,
  text: group.text === 'Classes' ? 'Components' : group.text,
}))

/**
 * Vite plugin that rewrites `importSync("specifier")` calls (from
 * @embroider/macros) into real static imports. Packages like ember-resources
 * ship un-compiled macro calls that the vite-plugin-ember shim cannot handle
 * at runtime.
 */
function embroiderImportSyncTransform(): Plugin {
  return {
    name: 'embroider-import-sync-transform',
    enforce: 'pre',
    transform(code, id) {
      if (!code.includes('importSync')) return null

      // Collect all importSync("specifier") calls
      const importSyncRe = /importSync\(["']([^"']+)["']\)/g
      const specifiers = new Map<string, string>()
      let match
      let counter = 0

      while ((match = importSyncRe.exec(code)) !== null) {
        const specifier = match[1]
        if (!specifiers.has(specifier)) {
          specifiers.set(specifier, `__importSync_${counter++}__`)
        }
      }

      if (specifiers.size === 0) return null

      // Build static imports and replace importSync calls
      let transformed = code
      const imports: string[] = []

      for (const [specifier, binding] of specifiers) {
        imports.push(`import * as ${binding} from "${specifier}";`)
        // Replace all importSync("specifier") with the binding
        transformed = transformed.replaceAll(
          new RegExp(`importSync\\(["']${specifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}["']\\)`, 'g'),
          binding,
        )
      }

      // Insert static imports after existing imports
      const lastImportIdx = transformed.lastIndexOf('\nimport ')
      if (lastImportIdx !== -1) {
        const lineEnd = transformed.indexOf('\n', lastImportIdx + 1)
        transformed =
          transformed.slice(0, lineEnd + 1) +
          imports.join('\n') +
          '\n' +
          transformed.slice(lineEnd + 1)
      } else {
        transformed = imports.join('\n') + '\n' + transformed
      }

      return { code: transformed, map: null }
    },
  }
}

const examplesSidebar = [
  {
    text: 'Getting Started',
    items: [
      { text: 'Introduction', link: '/examples/introduction' },
      { text: 'Installation', link: '/examples/installation' },
      { text: 'Basic Map', link: '/examples/basic-map' },
      { text: 'Markers & Popups', link: '/examples/markers-popups' },
      { text: 'Draggable Marker', link: '/examples/draggable-marker' },
      { text: 'GeoJSON Source', link: '/examples/geojson-source' },
      { text: 'Interactive Features', link: '/examples/interactive' },
    ],
  },
  {
    text: 'Data Visualization',
    items: [
      { text: 'Heatmap', link: '/examples/heatmap' },
      { text: 'Clusters', link: '/examples/clusters' },
      { text: 'Animate a Line', link: '/examples/animate-a-line' },
      { text: 'Animated Pulsing Icon', link: '/examples/animated-icon' },
    ],
  },
  {
    text: '3D & Terrain',
    items: [
      { text: '3D Buildings', link: '/examples/3d-buildings' },
      { text: '3D Tiles (Three.js)', link: '/examples/3d-tiles-threejs' },
      { text: '3D Terrain', link: '/examples/3d-terrain' },
    ],
  },
  {
    text: 'Advanced',
    items: [
      { text: 'Fly To', link: '/examples/fly-to' },
      { text: 'Video on Map', link: '/examples/video-on-map' },
      { text: 'Locate the User', link: '/examples/locate-user' },
      { text: 'Imperative API', link: '/examples/imperative-api' },
      { text: 'Reuse Maps', link: '/examples/reuse-maps' },
      { text: 'Mapbox Styles', link: '/examples/mapbox-styles' },
      { text: 'Authorized Tile Sources', link: '/examples/transform-request' },
    ],
  },
  {
    text: 'Plugins',
    items: [
      { text: 'Terra Draw', link: '/examples/terra-draw' },
      { text: 'Mapbox GL Draw', link: '/examples/mapbox-gl-draw' },
      { text: 'Geocoder (Nominatim)', link: '/examples/geocoder' },
    ],
  },
]

export default defineConfig({
  title: 'ember-maplibre-gl',
  description: 'Declarative MapLibre GL JS components for Ember.js',
  base: '/ember-maplibre-gl/',

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/ember-maplibre-gl/ember-icon.svg' }],
    ['meta', { property: 'og:title', content: 'ember-maplibre-gl' }],
    ['meta', { property: 'og:description', content: 'Declarative MapLibre GL JS components for Ember.js' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:url', content: 'https://johanrd.github.io/ember-maplibre-gl/' }],
    ['meta', { property: 'og:image', content: 'https://johanrd.github.io/ember-maplibre-gl/og-image.png' }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'ember-maplibre-gl' }],
    ['meta', { name: 'twitter:description', content: 'Declarative MapLibre GL JS components for Ember.js' }],
    ['meta', { name: 'twitter:image', content: 'https://johanrd.github.io/ember-maplibre-gl/og-image.png' }],
    ['meta', { name: 'algolia-site-verification', content: '52977A5FE3B2C1AB' }],
  ],

  vite: {
    plugins: [embroiderImportSyncTransform(), vitePluginEmber()],
    optimizeDeps: {
      esbuildOptions: {
        target: 'esnext',
      },
      exclude: [
        'ember-maplibre-gl',
        'ember-resources',
        'ember-modifier',
        '@glimmer/component',
        '@glimmer/tracking',
        '@ember/destroyable',
        '@ember/owner',
        '@ember/helper',
        '@ember/component',
        '@ember/template-compilation',
        'ember-source',
      ],
    },
  },

  markdown: {
    theme: {
      light: 'rose-pine-dawn',
      dark: 'monokai',
    },
    config(md) {
      emberFence(md)
    },
  },

  themeConfig: {
    logo: { light: '/logo.svg', dark: '/logo.svg' },
    siteTitle: false,
    search: {
      provider: 'local',
    },
    nav: [
      { text: 'Examples', link: '/examples/introduction' },
      { text: 'API', link: '/components/map' },
    ],
    sidebar: {
      '/examples/': examplesSidebar,
      '/components/': [
        {
          text: 'API',
          items: [
            { text: 'MapLibreGL', link: '/components/map' },
            { text: 'Source', link: '/components/source' },
            { text: 'Layer', link: '/components/layer' },
            { text: 'Marker', link: '/components/marker' },
            { text: 'Popup', link: '/components/popup' },
            { text: 'Control', link: '/components/control' },
            { text: 'Image', link: '/components/image' },
            { text: 'On (Events)', link: '/components/on' },
            { text: 'Call', link: '/components/call' },
          ],
        },
      ],
      '/api/': typedocSidebar,
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/johanrd/ember-maplibre-gl' },
    ],
  },
})
