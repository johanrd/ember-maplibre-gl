# Drawing with Terra Draw

[Terra Draw](https://github.com/JamesLMilner/terra-draw) is a library-agnostic drawing plugin that supports polygons, lines, points, circles, rectangles, freehand drawing, and more. The [`@watergis/maplibre-gl-terradraw`](https://www.npmjs.com/package/@watergis/maplibre-gl-terradraw) package provides a ready-made MapLibre control.

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

export default class TerraDrawDemo extends Component {
  @tracked featureCount = 0;

  onMapLoaded = async (map: Map) => {
    const [{ MaplibreTerradrawControl }] = await Promise.all([
      import('@watergis/maplibre-gl-terradraw'),
      import('@watergis/maplibre-gl-terradraw/dist/maplibre-gl-terradraw.css'),
    ]);

    const control = new MaplibreTerradrawControl({
      modes: [
        'point',
        'linestring',
        'polygon',
        'rectangle',
        'circle',
        'freehand',
        'select',
        'delete-selection',
        'delete',
      ],
      open: true,
    });

    map.addControl(control, 'top-left');

    const instance = control.getTerraDrawInstance();
    if (instance) {
      instance.on('change', () => {
        const snapshot = instance.getSnapshot();
        this.featureCount = snapshot.filter(
          (f) => f.properties?.mode !== 'select',
        ).length;
      });
    }
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        @mapLoaded={{this.onMapLoaded}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      />
      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 8px 12px; border-radius: 6px; font: 13px/1.4 monospace;">
        Features drawn: {{this.featureCount}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/draw-geometries-with-terra-draw/">Draw geometries with Terra Draw</a> example.</p>
