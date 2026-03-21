import type MapLibreGL from './components/maplibre-gl.gts';
import type MapLibreGLCall from './components/maplibre-gl-call.gts';
import type MapLibreGLOn from './components/maplibre-gl-on.gts';
import type MapLibreGLMarker from './components/maplibre-gl-marker.gts';
import type MapLibreGLPopup from './components/maplibre-gl-popup.gts';
import type MapLibreGLControl from './components/maplibre-gl-control.gts';
import type MapLibreGLSource from './components/maplibre-gl-source.gts';
import type MapLibreGLLayer from './components/maplibre-gl-layer.gts';
import type MapLibreGLImage from './components/maplibre-gl-image.gts';

export default interface EmberMapLibreGLRegistry {
  // Loose-mode (.hbs) resolution uses dasherized file names.
  // <MaplibreGl> resolves to maplibre-gl, <MaplibreGlMarker> to maplibre-gl-marker, etc.
  MaplibreGl: typeof MapLibreGL;
  MaplibreGlCall: typeof MapLibreGLCall;
  MaplibreGlOn: typeof MapLibreGLOn;
  MaplibreGlMarker: typeof MapLibreGLMarker;
  MaplibreGlPopup: typeof MapLibreGLPopup;
  MaplibreGlControl: typeof MapLibreGLControl;
  MaplibreGlSource: typeof MapLibreGLSource;
  MaplibreGlLayer: typeof MapLibreGLLayer;
  MaplibreGlImage: typeof MapLibreGLImage;
}
