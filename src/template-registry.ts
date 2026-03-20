import type MapLibreGL from './components/maplibre-gl.gts';
import type MapLibreGLCall from './components/maplibre-gl-call.gts';
import type MapLibreGLOn from './components/maplibre-gl-on.gts';
import type MapLibreGLMarker from './components/maplibre-gl-marker.gts';
import type MapLibreGLPopup from './components/maplibre-gl-popup.gts';
import type MapLibreGLControl from './components/maplibre-gl-control';
import type MapLibreGLSource from './components/maplibre-gl-source.gts';
import type MapLibreGLLayer from './components/maplibre-gl-layer.gts';
import type MapLibreGLImage from './components/maplibre-gl-image.gts';

export default interface EmberMapLibreGLRegistry {
  MapLibreGL: typeof MapLibreGL;
  MapLibreGLCall: typeof MapLibreGLCall;
  MapLibreGLOn: typeof MapLibreGLOn;
  MapLibreGLMarker: typeof MapLibreGLMarker;
  MapLibreGLPopup: typeof MapLibreGLPopup;
  MapLibreGLControl: typeof MapLibreGLControl;
  MapLibreGLSource: typeof MapLibreGLSource;
  MapLibreGLLayer: typeof MapLibreGLLayer;
  MapLibreGLImage: typeof MapLibreGLImage;
}
