export { default as MapLibreGL } from './components/maplibre-gl.gts';
export type { MapLibreGLSignature } from './components/maplibre-gl.gts';

export { default as MapLibreGLCall } from './components/maplibre-gl-call.gts';
export type {
  MapLibreGLCallSignature,
  MapInstance,
} from './components/maplibre-gl-call.gts';

export {
  default as MapLibreGLOn,
  mapOn,
} from './components/maplibre-gl-on.gts';

export { default as MapLibreGLMarker } from './components/maplibre-gl-marker.gts';
export type { MapLibreGLMarkerSignature } from './components/maplibre-gl-marker.gts';

export { default as MapLibreGLPopup } from './components/maplibre-gl-popup.gts';
export type { MapLibreGLPopupSignature } from './components/maplibre-gl-popup.gts';

export { default as MapLibreGLControl } from './components/maplibre-gl-control.ts';
export type { MapLibreGLControlSignature } from './components/maplibre-gl-control.ts';

export { default as MapLibreGLSource } from './components/maplibre-gl-source.gts';
export type { MapLibreGLSourceSignature } from './components/maplibre-gl-source.gts';

export { default as MapLibreGLLayer } from './components/maplibre-gl-layer.gts';
export type { MapLibreGLLayerSignature } from './components/maplibre-gl-layer.gts';

export {
  default as MapLibreGLImage,
  SvgLoadError,
} from './components/maplibre-gl-image.gts';
export type { MapLibreGLImageSignature } from './components/maplibre-gl-image.gts';

// Re-export common MapLibre types so consumers don't need to import from both packages
export type {
  Map,
  MapOptions,
  MapMouseEvent,
  MapTouchEvent,
  MapLayerMouseEvent,
  MapLayerTouchEvent,
  MapGeoJSONFeature,
  LngLat,
  LngLatLike,
  LngLatBounds,
  LngLatBoundsLike,
  Marker,
  MarkerOptions,
  Popup,
  PopupOptions,
  NavigationControl,
  GeolocateControl,
  ScaleControl,
  AttributionControl,
  TerrainControl,
  GlobeControl,
  IControl,
  SourceSpecification,
  LayerSpecification,
  FilterSpecification,
  StyleSpecification,
  GeoJSONSource,
  ImageSource,
  VideoSource,
  RasterTileSource,
  VectorTileSource,
  RequestTransformFunction,
} from 'maplibre-gl';
