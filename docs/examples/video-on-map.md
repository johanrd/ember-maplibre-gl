# Video on a Map

Overlay a video on a satellite map. Click the map to toggle playback.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import type { MapMouseEvent } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const videoStyle = {
  version: 8,
  sources: {
    satellite: {
      type: 'raster',
      tiles: ['https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2020_3857/default/g/{z}/{y}/{x}.jpg'],
      tileSize: 256,
    },
    video: {
      type: 'video',
      urls: [
        'https://static-assets.mapbox.com/mapbox-gl-js/drone.mp4',
        'https://static-assets.mapbox.com/mapbox-gl-js/drone.webm',
      ],
      coordinates: [
        [-122.51596391201019, 37.56238816766053],
        [-122.51467645168304, 37.56410183312965],
        [-122.51309394836426, 37.563391708549425],
        [-122.51423120498657, 37.56161849366671],
      ],
    },
  },
  layers: [
    { id: 'background', type: 'background', paint: { 'background-color': 'rgb(4,7,14)' } },
    { id: 'satellite', type: 'raster', source: 'satellite' },
    { id: 'video', type: 'raster', source: 'video' },
  ],
};

export default class VideoOnMapDemo extends Component {
  @tracked playing = true;

  togglePlayback = (e: MapMouseEvent) => {
    this.playing = !this.playing;
    const video = e.target.getSource('video');
    if (this.playing) {
      video.play();
    } else {
      video.pause();
    }
  };

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{hash style=videoStyle center=(array -122.514426 37.562984) zoom=17 minZoom=14 bearing=-96}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        <map.on @event="click" @action={{this.togglePlayback}} />
      </MapLibreGL>
      <div style="position: absolute; bottom: 20px; left: 12px; z-index: 1; background: rgba(0,0,0,0.7); color: white; padding: 6px 12px; border-radius: 6px; font: 13px/1 system-ui;">
        Click map to {{if this.playing "pause" "play"}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/add-a-video/">Add a video</a> example.</p>
