# Animate a Line

Progressively draw a flight path from New York to London, one coordinate at a time.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-40, 45] as [number, number],
  zoom: 2.5,
};

// Generate a great-circle arc from NYC to London
function generateArc(start: [number, number], end: [number, number], steps = 200): [number, number][] {
  const coords: [number, number][] = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const lng = start[0] + (end[0] - start[0]) * t;
    const lat = start[1] + (end[1] - start[1]) * t
      + Math.sin(t * Math.PI) * 8; // arc above the straight line
    coords.push([lng, lat]);
  }
  return coords;
}

const fullRoute = generateArc([-74.006, 40.7128], [-0.1276, 51.5074]);

const lineLayer = {
  type: 'line' as const,
  layout: { 'line-cap': 'round' as const, 'line-join': 'round' as const },
  paint: { 'line-color': '#E04E39', 'line-width': 4, 'line-opacity': 0.9 },
};

const dotLayer = {
  type: 'circle' as const,
  paint: { 'circle-radius': 7, 'circle-color': '#E04E39', 'circle-stroke-color': '#fff', 'circle-stroke-width': 2 },
};

export default class AnimateLineDemo extends Component {
  @tracked isPaused = false;
  map: Map | null = null;
  animation: number | null = null;
  currentIndex = 0;

  geojson = {
    type: 'FeatureCollection' as const,
    features: [{
      type: 'Feature' as const,
      geometry: { type: 'LineString' as const, coordinates: [fullRoute[0]] },
    }],
  };

  routeSource = {
    type: 'geojson' as const,
    data: this.geojson,
  };

  dotSource = {
    type: 'geojson' as const,
    data: { type: 'Point' as const, coordinates: fullRoute[0] },
  };

  onMapLoaded = (map: Map) => {
    this.map = map;
    this.animate();
  };

  animate = () => {
    if (this.currentIndex < fullRoute.length) {
      this.geojson.features[0].geometry.coordinates.push(fullRoute[this.currentIndex]);
      this.map!.getSource('route')!.setData(this.geojson);
      this.map!.getSource('dot')!.setData({
        type: 'Point',
        coordinates: fullRoute[this.currentIndex],
      });
      this.currentIndex++;
    } else {
      // Reset and loop
      this.currentIndex = 0;
      this.geojson.features[0].geometry.coordinates = [fullRoute[0]];
    }
    this.animation = requestAnimationFrame(this.animate);
  };

  togglePause = () => {
    this.isPaused = !this.isPaused;
    if (this.isPaused) {
      cancelAnimationFrame(this.animation!);
    } else {
      this.animate();
    }
  };

  willDestroy() {
    super.willDestroy();
    cancelAnimationFrame(this.animation!);
  }

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        @mapLoaded={{this.onMapLoaded}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        <map.source @sourceId="route" @options={{this.routeSource}} as |source|>
          <source.layer @options={{lineLayer}} />
        </map.source>
        <map.source @sourceId="dot" @options={{this.dotSource}} as |source|>
          <source.layer @options={{dotLayer}} />
        </map.source>
      </MapLibreGL>
      <button
        type="button"
        {{on "click" this.togglePause}}
        style="position: absolute; top: 12px; left: 12px; z-index: 1; padding: 6px 14px; background: #fff; border: 1px solid #ddd; border-radius: 6px; font: 13px/1 system-ui; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"
      >{{if this.isPaused "Play" "Pause"}}</button>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/animate-a-line/">Animate a line</a> example.</p>
