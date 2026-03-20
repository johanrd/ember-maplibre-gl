# Animated Pulsing Icon

Add a pulsing dot to the map using MapLibre's `StyleImageInterface` with the Canvas API.

```gts live preview
import Component from '@glimmer/component';
import type { Map, StyleImageInterface } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [0, 0] as [number, number],
  zoom: 2,
};

const pointSource = {
  type: 'geojson' as const,
  data: {
    type: 'FeatureCollection' as const,
    features: [{ type: 'Feature' as const, geometry: { type: 'Point' as const, coordinates: [0, 0] } }],
  },
};

const pointLayer = {
  type: 'symbol' as const,
  layout: { 'icon-image': 'pulsing-dot' },
};

export default class AnimatedIconDemo extends Component {
  // StyleImageInterface requires imperative addImage — no declarative equivalent
  onMapLoaded = (map: Map) => {
    const size = 200;
    const pulsingDot: StyleImageInterface & { context: CanvasRenderingContext2D | null } = {
      width: size,
      height: size,
      data: new Uint8Array(size * size * 4),
      context: null,
      onAdd() {
        const canvas = document.createElement('canvas');
        canvas.width = this.width;
        canvas.height = this.height;
        this.context = canvas.getContext('2d');
      },
      render() {
        const duration = 1000;
        const t = (performance.now() % duration) / duration;
        const radius = (size / 2) * 0.3;
        const outerRadius = (size / 2) * 0.7 * t + radius;
        const ctx = this.context!;
        ctx.clearRect(0, 0, this.width, this.height);
        ctx.beginPath();
        ctx.arc(this.width / 2, this.height / 2, outerRadius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(224, 78, 57, ${1 - t})`;
        ctx.fill();
        ctx.beginPath();
        ctx.arc(this.width / 2, this.height / 2, radius, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(224, 78, 57, 1)';
        ctx.strokeStyle = 'white';
        ctx.lineWidth = 2 + 4 * (1 - t);
        ctx.fill();
        ctx.stroke();
        this.data = ctx.getImageData(0, 0, this.width, this.height).data;
        map.triggerRepaint();
        return true;
      },
    };

    map.addImage('pulsing-dot', pulsingDot, { pixelRatio: 2 });
  };

  <template>
    <MapLibreGL
      @initOptions={{mapOptions}}
      @mapLoaded={{this.onMapLoaded}}
      style="height: 500px; width: 100%; border-radius: 8px;"
    as |map|>
      <map.source @options={{pointSource}} as |source|>
        <source.layer @options={{pointLayer}} />
      </map.source>
    </MapLibreGL>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/add-an-animated-icon-to-the-map/">Add an animated icon to the map</a> example.</p>
