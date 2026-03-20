# Imperative API

For most use cases, the declarative components (`<map.source>`, `<source.layer>`, `<map.marker>`, etc.) are the right choice. But sometimes you need direct access to the MapLibre `Map` instance — for custom WebGL layers, runtime style queries, or APIs the addon doesn't wrap.

Use the `@mapLoaded` callback to get the map instance:

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [-122.4194, 37.7749] as [number, number],
  zoom: 11,
};

export default class ImperativeDemo extends Component {
  @tracked bearing = 0;
  @tracked pitch = 0;
  @tracked zoom = 11;
  map: Map | null = null;

  onMapLoaded = (map: Map) => {
    this.map = map;

    // Direct API: query rendered features on click
    map.on('click', (e) => {
      const features = map.queryRenderedFeatures(e.point);
      const names = features
        .map((f) => f.properties?.name)
        .filter(Boolean)
        .slice(0, 3);
      if (names.length) {
        console.log('Clicked features:', names.join(', '));
      }
    });

    // Direct API: update tracked state on move
    map.on('move', () => {
      this.bearing = Math.round(map.getBearing());
      this.pitch = Math.round(map.getPitch());
      this.zoom = Math.round(map.getZoom() * 10) / 10;
    });
  };

  spin = () => {
    this.map?.easeTo({
      bearing: this.bearing + 90,
      duration: 1000,
    });
  };

  resetNorth = () => {
    this.map?.easeTo({
      bearing: 0,
      pitch: 0,
      duration: 500,
    });
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        @mapLoaded={{this.onMapLoaded}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      />
      <div style="position: absolute; top: 12px; left: 12px; z-index: 1; display: flex; gap: 6px;">
        <button
          type="button"
          {{on "click" this.spin}}
          style="padding: 6px 14px; background: #fff; border: 1px solid #ddd; border-radius: 6px; font: 13px/1 system-ui; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"
        >Spin 90°</button>
        <button
          type="button"
          {{on "click" this.resetNorth}}
          style="padding: 6px 14px; background: #fff; border: 1px solid #ddd; border-radius: 6px; font: 13px/1 system-ui; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"
        >Reset North</button>
      </div>
      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 8px 12px; border-radius: 6px; font: 13px/1.4 monospace;">
        Bearing: {{this.bearing}}° · Pitch: {{this.pitch}}° · Zoom: {{this.zoom}}
      </div>
    </div>
  </template>
}
```
