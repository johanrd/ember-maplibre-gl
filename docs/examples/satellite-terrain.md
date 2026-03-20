# Satellite Map with 3D Terrain

Display satellite imagery with 3D terrain elevation using MapLibre's globe projection.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { Map } from 'maplibre-gl';
import { NavigationControl, TerrainControl } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [11.39085, 47.27574] as [number, number],
  zoom: 12,
  pitch: 70,
  maxPitch: 85,
};

const satelliteSource = {
  type: 'raster' as const,
  tiles: ['https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2020_3857/default/g/{z}/{y}/{x}.jpg'],
  tileSize: 256,
};

const terrainSource = {
  type: 'raster-dem' as const,
  url: 'https://demotiles.maplibre.org/terrain-tiles/tiles.json',
  tileSize: 256,
};

const hillshadeSource = {
  type: 'raster-dem' as const,
  url: 'https://demotiles.maplibre.org/terrain-tiles/tiles.json',
  tileSize: 256,
};

const satelliteLayer = {
  type: 'raster' as const,
};

const hillshadeLayer = {
  type: 'hillshade' as const,
  paint: { 'hillshade-shadow-color': '#473B24' },
};

export default class SatelliteTerrainDemo extends Component {
  navControl = new NavigationControl({ visualizePitch: true });
  terrainControl = new TerrainControl({ source: 'terrainSource', exaggeration: 1 });

  @tracked satelliteBefore: string | undefined;

  // Terrain has no declarative component — use @mapLoaded for setTerrain and layer ordering
  onMapLoaded = (map: Map) => {
    const layers = map.getStyle().layers;
    const firstNonFill = layers.find(l => l.type !== 'fill' && l.type !== 'background');
    this.satelliteBefore = firstNonFill?.id;
    map.setTerrain({ source: 'terrainSource', exaggeration: 1 });
  };

  <template>
    <MapLibreGL
      @initOptions={{mapOptions}}
      @mapLoaded={{this.onMapLoaded}}
      style="height: 500px; width: 100%; border-radius: 8px;"
    as |map|>
      <map.source @sourceId="satellite" @options={{satelliteSource}} as |source|>
        <source.layer @options={{satelliteLayer}} @before={{this.satelliteBefore}} />
      </map.source>
      <map.source @sourceId="terrainSource" @options={{terrainSource}} />
      <map.source @sourceId="hillshadeSource" @options={{hillshadeSource}} as |source|>
        <source.layer @options={{hillshadeLayer}} />
      </map.source>
      <map.control @control={{this.navControl}} @position="top-right" />
      <map.control @control={{this.terrainControl}} @position="top-right" />
    </MapLibreGL>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/display-a-hybrid-satellite-map-with-terrain-elevation/">Display a hybrid satellite map with terrain elevation</a> example.</p>
