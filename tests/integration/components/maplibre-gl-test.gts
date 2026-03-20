import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, waitUntil, find } from '@ember/test-helpers';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map } from 'maplibre-gl';
import mapboxgl from 'mapbox-gl';

const STYLE = 'https://demotiles.maplibre.org/style.json';

module('Integration | Component | maplibre-gl', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a map', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
        >
          <span data-test-loaded>loaded</span>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.dom('[data-test-loaded]').exists('map loaded and yielded content');
  });

  test('it calls mapLoaded when map is ready', async function (assert) {
    let mapInstance: Map | undefined;
    const onMapLoaded = (map: Map) => {
      mapInstance = map;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          @mapLoaded={{onMapLoaded}}
          style="height:200px;"
        >
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.ok(mapInstance, 'mapLoaded callback received the map instance');
  });

  test('it yields sub-components after loading', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:200px;"
          as |map|
        >
          <span data-test-source>{{if map.source "yes" "no"}}</span>
          <span data-test-layer>{{if map.layer "yes" "no"}}</span>
          <span data-test-marker>{{if map.marker "yes" "no"}}</span>
          <span data-test-popup>{{if map.popup "yes" "no"}}</span>
          <span data-test-on>{{if map.on "yes" "no"}}</span>
          <span data-test-control>{{if map.control "yes" "no"}}</span>
          <span data-test-image>{{if map.image "yes" "no"}}</span>
          <span data-test-call>{{if map.call "yes" "no"}}</span>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-source]'), { timeout: 10000 });

    assert.dom('[data-test-source]').hasText('yes');
    assert.dom('[data-test-layer]').hasText('yes');
    assert.dom('[data-test-marker]').hasText('yes');
    assert.dom('[data-test-popup]').hasText('yes');
    assert.dom('[data-test-on]').hasText('yes');
    assert.dom('[data-test-control]').hasText('yes');
    assert.dom('[data-test-image]').hasText('yes');
    assert.dom('[data-test-call]').hasText('yes');
  });

  test('it works with Mapbox GL JS v1 via @mapLib', async function (assert) {
    let mapInstance: Map | undefined;

    const onMapLoaded = (map: Map) => {
      mapInstance = map;
    };

    const MapLib = mapboxgl.Map as unknown as new (...args: unknown[]) => Map;

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          @mapLib={{MapLib}}
          @mapLoaded={{onMapLoaded}}
          style="height:200px;"
        >
          <span data-test-mapbox-loaded>loaded</span>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-mapbox-loaded]'), {
      timeout: 10000,
    });
    assert.dom('[data-test-mapbox-loaded]').exists('Mapbox GL v1 map loaded');
    assert.ok(mapInstance, 'mapLoaded received the Mapbox map instance');
    assert.ok(
      typeof mapInstance!.flyTo === 'function',
      'map instance has flyTo method',
    );
  });

  test('it yields the map instance', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:200px;"
          as |map|
        >
          <span data-test-instance>{{if map.instance "yes" "no"}}</span>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-instance]'), { timeout: 10000 });
    assert.dom('[data-test-instance]').hasText('yes');
  });
});
