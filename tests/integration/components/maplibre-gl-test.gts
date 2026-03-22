import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map } from 'maplibre-gl';
import mapboxgl from 'mapbox-gl';

const STYLE = { version: 8 as const, sources: {}, layers: [] };
const STYLE_URL = 'https://demotiles.maplibre.org/style.json';

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
          @initOptions={{hash style=STYLE_URL center=(array 0 0) zoom=1}}
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

  test('it yields the error block when map construction fails', async function (assert) {
    const BrokenMap = class {
      constructor() {
        throw new Error('WebGL not supported');
      }
    } as unknown as new (...args: unknown[]) => Map;

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLib={{BrokenMap}}
          style="height:200px;"
        >
          <:default>
            <span data-test-should-not-render>loaded</span>
          </:default>
          <:error as |error|>
            <span data-test-error>{{error.message}}</span>
          </:error>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-error]'), { timeout: 5000 });
    assert
      .dom('[data-test-error]')
      .hasText('WebGL not supported', 'error block renders the error message');
    assert
      .dom('[data-test-should-not-render]')
      .doesNotExist('default block is not rendered');
  });

  test('it reuses the map instance when @reuseMaps is true', async function (assert) {
    class ShowState {
      @tracked show = true;
    }

    let firstMap: Map | undefined;
    let secondMap: Map | undefined;
    const state = new ShowState();
    const captureMap = (m: Map) => {
      if (!firstMap) firstMap = m;
      else secondMap = m;
    };

    // First render
    await render(
      <template>
        {{#if state.show}}
          <MapLibreGL
            @initOptions={{hash style=STYLE_URL center=(array 0 0) zoom=1}}
            @reuseMaps={{true}}
            @mapLoaded={{captureMap}}
            style="height:200px;"
          >
            <span data-test-reuse-loaded>loaded</span>
          </MapLibreGL>
        {{/if}}
      </template>,
    );

    await waitUntil(() => find('[data-test-reuse-loaded]'), { timeout: 10000 });
    assert.ok(firstMap, 'first map instance captured');

    const firstCanvas = firstMap!.getCanvas();

    // Destroy
    state.show = false;
    await settled();

    // Re-render
    state.show = true;
    await settled();

    await waitUntil(() => find('[data-test-reuse-loaded]'), { timeout: 10000 });
    assert.ok(secondMap, 'second map instance captured');
    assert.strictEqual(
      secondMap!.getCanvas(),
      firstCanvas,
      'same WebGL canvas reused across remounts',
    );
  });
});
