# Geocoding with Nominatim

Search for places using [OpenStreetMap Nominatim](https://nominatim.openstreetmap.org/), a free geocoding API. Results appear as markers on the map, and clicking a marker shows the place name in a popup.

```gts live preview
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import type { Map } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { LngLatBounds } from 'maplibre-gl';

interface GeocoderResult {
  name: string;
  center: [number, number];
  bbox: [number, number, number, number];
}

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/liberty',
  center: [10.4, 55.4],
  zoom: 4,
};

export default class GeocoderDemo extends Component {
  @tracked query = '';
  @tracked results: GeocoderResult[] = [];
  @tracked selectedResult: GeocoderResult | null = null;
  map: Map | null = null;
  debounceTimer: ReturnType<typeof setTimeout> | null = null;

  onMapLoaded = (map: Map) => {
    this.map = map;
  };

  onInput = (event: Event) => {
    this.query = (event.target as HTMLInputElement).value;
    clearTimeout(this.debounceTimer);
    if (this.query.trim().length < 2) {
      this.results = [];
      this.selectedResult = null;
      return;
    }
    this.debounceTimer = setTimeout(() => this.search(), 400);
  };

  search = async () => {
    const q = this.query.trim();
    if (!q) return;
    try {
      const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}&format=geojson&limit=5&addressdetails=1`;
      const response = await fetch(url);
      const geojson = await response.json();
      this.results = geojson.features.map((feature) => ({
        name: feature.properties.display_name,
        center: [
          feature.bbox[0] + (feature.bbox[2] - feature.bbox[0]) / 2,
          feature.bbox[1] + (feature.bbox[3] - feature.bbox[1]) / 2,
        ],
        bbox: feature.bbox,
      }));
      this.selectedResult = null;
      if (this.results.length > 0 && this.map) {
        const bounds = this.results.reduce(
          (b, r) => b.extend(r.center),
          new LngLatBounds(this.results[0].center, this.results[0].center),
        );
        this.map.fitBounds(bounds, { padding: 80, maxZoom: 12 });
      }
    } catch (e) {
      console.error('Geocoding failed:', e);
    }
  };

  selectResult = (result: GeocoderResult) => {
    this.selectedResult = result;
    if (this.map && result.bbox) {
      this.map.fitBounds(
        [[result.bbox[0], result.bbox[1]], [result.bbox[2], result.bbox[3]]],
        { padding: 60, maxZoom: 16 },
      );
    }
  };

  isSelected = (result: GeocoderResult) => Object.is(this.selectedResult, result);

  clearSearch = () => {
    this.query = '';
    this.results = [];
    this.selectedResult = null;
  };

  willDestroy() {
    super.willDestroy();
    clearTimeout(this.debounceTimer);
  }

  <template>
    <div style="position: relative;">
      <MapLibreGL
        @initOptions={{mapOptions}}
        @mapLoaded={{this.onMapLoaded}}
        style="height: 500px; width: 100%; border-radius: 8px;"
      as |map|>
        {{#each this.results as |result|}}
          <map.marker @lngLat={{result.center}}>
            <div
              role="button"
              {{on "click" (fn this.selectResult result)}}
              style="width: 20px; height: 20px; background: #E04E39; border: 3px solid white; border-radius: 50%; box-shadow: 0 2px 6px rgba(0,0,0,0.3); cursor: pointer;"
            />
          </map.marker>
        {{/each}}

        {{#if this.selectedResult}}
          <map.popup @lngLat={{this.selectedResult.center}}>
            <div style="padding: 8px 12px; font: 13px/1.4 system-ui; max-width: 260px;">
              {{this.selectedResult.name}}
            </div>
          </map.popup>
        {{/if}}
      </MapLibreGL>

      <div style="position: absolute; top: 12px; left: 12px; z-index: 1; display: flex; flex-direction: column; gap: 4px; width: 320px;">
        <div style="display: flex; gap: 4px;">
          <input
            type="text"
            value={{this.query}}
            placeholder="Search for a place..."
            {{on "input" this.onInput}}
            style="flex: 1; padding: 8px 12px; border: 1px solid #ddd; border-radius: 6px; font: 14px system-ui; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"
          />
          {{#if this.query}}
            <button
              type="button"
              {{on "click" this.clearSearch}}
              style="padding: 8px 12px; background: #fff; border: 1px solid #ddd; border-radius: 6px; font: 14px system-ui; cursor: pointer; box-shadow: 0 1px 3px rgba(0,0,0,0.15);"
            >Clear</button>
          {{/if}}
        </div>

        {{#if this.results.length}}
          <ul style="list-style: none; margin: 0; padding: 0; background: #fff; border: 1px solid #ddd; border-radius: 6px; box-shadow: 0 2px 8px rgba(0,0,0,0.15); max-height: 240px; overflow-y: auto;">
            {{#each this.results as |result|}}
              <li>
                <button
                  type="button"
                  {{on "click" (fn this.selectResult result)}}
                  style="display: block; width: 100%; text-align: left; padding: 8px 12px; border: none; background: transparent; font: 13px/1.4 system-ui; cursor: pointer; border-bottom: 1px solid #eee;"
                >{{result.name}}</button>
              </li>
            {{/each}}
          </ul>
        {{/if}}
      </div>
    </div>
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/geocode-with-nominatim/">Geocode with Nominatim</a> example.</p>
