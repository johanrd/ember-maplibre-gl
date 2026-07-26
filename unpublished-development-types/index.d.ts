// Vite's `?worker&url` asset query, used for the MapLibre worker setup in
// components/maplibre-gl.gts. The main tsconfig gets this from vite/client;
// tsconfig.publish.json does not include vite/client, so declare it here.
declare module 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url' {
  const url: string;
  export default url;
}
