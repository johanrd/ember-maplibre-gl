# 3D Buildings

Display building heights as 3D extrusions. Buildings are color-coded by height, from gray to blue.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-74.0066, 40.7135] as [number, number],
  zoom: 15.5,
  pitch: 45,
  bearing: -17.6,
};

const buildingSource = {
  url: 'https://tiles.openfreemap.org/planet',
  type: 'vector' as const,
};

const buildingLayer = {
  'source-layer': 'building',
  type: 'fill-extrusion' as const,
  minzoom: 15,
  filter: ['!=', ['get', 'hide_3d'], true],
  paint: {
    'fill-extrusion-color': [
      'interpolate', ['linear'], ['get', 'render_height'],
      0, 'lightgray', 200, 'royalblue', 400, 'lightblue',
    ],
    'fill-extrusion-height': [
      'interpolate', ['linear'], ['zoom'],
      15, 0, 16, ['get', 'render_height'],
    ],
    'fill-extrusion-base': [
      'case', ['>=', ['get', 'zoom'], 16],
      ['get', 'render_min_height'], 0,
    ],
  },
};

export default class Buildings3DDemo extends Component {
  @tracked labelLayerId: string | undefined;

  onMapLoaded = (map: Map) => {
    const layers = map.getStyle().layers;
    for (const layer of layers) {
      if (layer.type === 'symbol' && layer.layout?.['text-field']) {
        this.labelLayerId = layer.id;
        break;
      }
    }
  };

  <template>
    <MapLibreGL
      @initOptions={{mapOptions}}
      @mapLoaded={{this.onMapLoaded}}
      style="height: 500px; width: 100%; border-radius: 8px;"
    as |map|>
      <map.source @options={{buildingSource}} as |source|>
        <source.layer @options={{buildingLayer}} @before={{this.labelLayerId}} />
      </map.source>
    </MapLibreGL>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/display-buildings-in-3d/">Display buildings in 3D</a> example.</p>
