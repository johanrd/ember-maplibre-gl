# Drawing with Mapbox GL Draw

[Mapbox GL Draw](https://github.com/mapbox/mapbox-gl-draw) is a popular drawing plugin originally built for Mapbox GL JS. It works with MapLibre after patching a few CSS class constants. This example shows polygon, line, and point drawing with live area calculation using [Turf.js](https://turfjs.org/).

The draw plugin and Turf are dynamically imported when the map loads, keeping the initial bundle small.

> **Note:** You must import the Mapbox GL Draw CSS for the toolbar icons to render correctly.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-91.874, 42.76],
  zoom: 12,
};

export default class MapboxGlDrawDemo extends Component {
  @tracked area: string | null = null;
  @tracked featureCount = 0;
  draw: any = null;
  turf: any = null;

  onMapLoaded = async (map: Map) => {
    const [{ default: MapboxDraw }, turf] = await Promise.all([
      import('@mapbox/mapbox-gl-draw'),
      import('@turf/turf'),
      import('@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css'),
    ]);

    // Patch class constants so MapboxDraw works with MapLibre
    MapboxDraw.constants.classes.CANVAS = 'maplibregl-canvas';
    MapboxDraw.constants.classes.CONTROL_BASE = 'maplibregl-ctrl';
    MapboxDraw.constants.classes.CONTROL_PREFIX = 'maplibregl-ctrl-';
    MapboxDraw.constants.classes.CONTROL_GROUP = 'maplibregl-ctrl-group';
    MapboxDraw.constants.classes.ATTRIBUTION = 'maplibregl-ctrl-attrib';

    this.turf = turf;

    // Custom styles required for MapLibre compatibility
    // https://github.com/mapbox/mapbox-gl-draw/issues/1357
    const styles = [
      { id: 'gl-draw-polygon-fill-inactive', type: 'fill', filter: ['all', ['==', 'active', 'false'], ['==', '$type', 'Polygon'], ['!=', 'mode', 'static']], paint: { 'fill-color': '#3bb2d0', 'fill-outline-color': '#3bb2d0', 'fill-opacity': 0.1 } },
      { id: 'gl-draw-polygon-fill-active', type: 'fill', filter: ['all', ['==', 'active', 'true'], ['==', '$type', 'Polygon']], paint: { 'fill-color': '#fbb03b', 'fill-outline-color': '#fbb03b', 'fill-opacity': 0.1 } },
      { id: 'gl-draw-polygon-midpoint', type: 'circle', filter: ['all', ['==', '$type', 'Point'], ['==', 'meta', 'midpoint']], paint: { 'circle-radius': 3, 'circle-color': '#fbb03b' } },
      { id: 'gl-draw-polygon-stroke-inactive', type: 'line', filter: ['all', ['==', 'active', 'false'], ['==', '$type', 'Polygon'], ['!=', 'mode', 'static']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#3bb2d0', 'line-width': 2 } },
      { id: 'gl-draw-polygon-stroke-active', type: 'line', filter: ['all', ['==', 'active', 'true'], ['==', '$type', 'Polygon']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#fbb03b', 'line-dasharray': [0.2, 2], 'line-width': 2 } },
      { id: 'gl-draw-line-inactive', type: 'line', filter: ['all', ['==', 'active', 'false'], ['==', '$type', 'LineString'], ['!=', 'mode', 'static']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#3bb2d0', 'line-width': 2 } },
      { id: 'gl-draw-line-active', type: 'line', filter: ['all', ['==', '$type', 'LineString'], ['==', 'active', 'true']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#fbb03b', 'line-dasharray': [0.2, 2], 'line-width': 2 } },
      { id: 'gl-draw-polygon-and-line-vertex-stroke-inactive', type: 'circle', filter: ['all', ['==', 'meta', 'vertex'], ['==', '$type', 'Point'], ['!=', 'mode', 'static']], paint: { 'circle-radius': 5, 'circle-color': '#fff' } },
      { id: 'gl-draw-polygon-and-line-vertex-inactive', type: 'circle', filter: ['all', ['==', 'meta', 'vertex'], ['==', '$type', 'Point'], ['!=', 'mode', 'static']], paint: { 'circle-radius': 3, 'circle-color': '#fbb03b' } },
      { id: 'gl-draw-point-point-stroke-inactive', type: 'circle', filter: ['all', ['==', 'active', 'false'], ['==', '$type', 'Point'], ['==', 'meta', 'feature'], ['!=', 'mode', 'static']], paint: { 'circle-radius': 5, 'circle-opacity': 1, 'circle-color': '#fff' } },
      { id: 'gl-draw-point-inactive', type: 'circle', filter: ['all', ['==', 'active', 'false'], ['==', '$type', 'Point'], ['==', 'meta', 'feature'], ['!=', 'mode', 'static']], paint: { 'circle-radius': 3, 'circle-color': '#3bb2d0' } },
      { id: 'gl-draw-point-stroke-active', type: 'circle', filter: ['all', ['==', '$type', 'Point'], ['==', 'active', 'true'], ['!=', 'meta', 'midpoint']], paint: { 'circle-radius': 7, 'circle-color': '#fff' } },
      { id: 'gl-draw-point-active', type: 'circle', filter: ['all', ['==', '$type', 'Point'], ['!=', 'meta', 'midpoint'], ['==', 'active', 'true']], paint: { 'circle-radius': 5, 'circle-color': '#fbb03b' } },
      { id: 'gl-draw-polygon-fill-static', type: 'fill', filter: ['all', ['==', 'mode', 'static'], ['==', '$type', 'Polygon']], paint: { 'fill-color': '#404040', 'fill-outline-color': '#404040', 'fill-opacity': 0.1 } },
      { id: 'gl-draw-polygon-stroke-static', type: 'line', filter: ['all', ['==', 'mode', 'static'], ['==', '$type', 'Polygon']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#404040', 'line-width': 2 } },
      { id: 'gl-draw-line-static', type: 'line', filter: ['all', ['==', 'mode', 'static'], ['==', '$type', 'LineString']], layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#404040', 'line-width': 2 } },
      { id: 'gl-draw-point-static', type: 'circle', filter: ['all', ['==', 'mode', 'static'], ['==', '$type', 'Point']], paint: { 'circle-radius': 5, 'circle-color': '#404040' } },
    ];

    this.draw = new MapboxDraw({
      displayControlsDefault: false,
      controls: {
        polygon: true,
        line_string: true,
        point: true,
        trash: true,
      },
      styles,
    });

    map.addControl(this.draw, 'top-left');

    map.on('draw.create', this.updateArea);
    map.on('draw.delete', this.updateArea);
    map.on('draw.update', this.updateArea);
  };

  updateArea = () => {
    const data = this.draw.getAll();
    this.featureCount = data.features.length;

    // Calculate area of all polygon features
    const polygons = data.features.filter(
      (f) => f.geometry.type === 'Polygon'
    );

    if (polygons.length > 0) {
      const collection = {
        type: 'FeatureCollection',
        features: polygons,
      };
      const areaM2 = this.turf.area(collection);
      if (areaM2 > 1_000_000) {
        this.area = `${(areaM2 / 1_000_000).toFixed(2)} km²`;
      } else {
        this.area = `${Math.round(areaM2).toLocaleString()} m²`;
      }
    } else {
      this.area = null;
    }
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        @mapLoaded={{this.onMapLoaded}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      />

      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 10px 14px; border-radius: 6px; font: 13px/1.5 system-ui;">
        <div>Features: <strong>{{this.featureCount}}</strong></div>
        {{#if this.area}}
          <div>Polygon area: <strong>{{this.area}}</strong></div>
        {{else}}
          <div style="color: #aaa;">Draw a polygon to measure area</div>
        {{/if}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/draw-polygon-with-mapbox-gl-draw/">Draw polygon with Mapbox GL Draw</a> example.</p>
