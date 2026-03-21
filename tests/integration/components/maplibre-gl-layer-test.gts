import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map, LayerSpecification } from 'maplibre-gl';
import sinon from 'sinon';

const STYLE = 'https://demotiles.maplibre.org/style.json';

import type { FeatureCollection } from 'geojson';

const GEOJSON: FeatureCollection = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: {},
      geometry: { type: 'Point', coordinates: [0, 0] },
    },
  ],
};

type DistributiveOmit<T, K extends string> = T extends unknown
  ? Omit<T, K>
  : never;

type TestLayerOptions = DistributiveOmit<
  LayerSpecification,
  'id' | 'source'
> & {
  id?: string;
  source?: string;
};

class State {
  @tracked show = true;
  @tracked layerOptions!: TestLayerOptions;
}

module('Integration | Component | maplibre-gl-layer', function (hooks) {
  setupRenderingTest(hooks);

  test('it adds a layer to the map', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer
              @options={{hash
                type="circle"
                paint=(hash circle-color="#007cbf" circle-radius=10)
              }}
              as |layer|
            >
              <span data-test-layer-id>{{layer.id}}</span>
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-layer-id]'), { timeout: 10000 });
    const layerId = find('[data-test-layer-id]')!.textContent.trim();
    const layer = map?.getLayer(layerId);
    assert.ok(layer, 'layer exists on map');
    assert.strictEqual(layer?.type, 'circle', 'correct layer type');
  });

  test('it generates a layer id and removes on destroy', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            {{#if state.show}}
              <source.layer @options={{hash type="circle"}} as |layer|>
                <span data-test-layer-id>{{layer.id}}</span>
              </source.layer>
            {{/if}}
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-layer-id]'), { timeout: 10000 });
    const layerId = find('[data-test-layer-id]')!.textContent.trim();
    assert.ok(layerId, 'layer id was auto-generated');
    assert.ok(map?.getLayer(layerId), 'layer exists');

    state.show = false;
    await settled();

    assert.notOk(map?.getLayer(layerId), 'layer removed after destroy');
  });

  test('it defaults layer type to "line"', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{hash type="line"}} as |layer|>
              <span data-test-layer-id>{{layer.id}}</span>
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-layer-id]'), { timeout: 10000 });
    const layerId = find('[data-test-layer-id]')!.textContent.trim();
    assert.strictEqual(
      map?.getLayer(layerId)?.type,
      'line',
      'defaults to line',
    );
  });

  test('it supports the before option', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{hash id="first-layer" type="circle"}} />
            <source.layer
              @options={{hash id="before-test" type="circle"}}
              @before="first-layer"
            >
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    // Both layers should exist
    assert.ok(map?.getLayer('first-layer'), 'first layer exists');
    assert.ok(map?.getLayer('before-test'), 'before layer exists');

    // Verify layer ordering: 'before-test' should be rendered before 'first-layer'
    const layers = map?.getStyle().layers ?? [];
    const beforeIdx = layers.findIndex((l) => l.id === 'before-test');
    const firstIdx = layers.findIndex((l) => l.id === 'first-layer');
    assert.true(
      beforeIdx < firstIdx,
      'before-test layer is ordered before first-layer',
    );
  });

  test('it updates layout properties', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.layerOptions = {
      id: 'layout-test',
      type: 'circle',
      layout: { visibility: 'none' },
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{state.layerOptions}}>
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.strictEqual(
      map?.getLayoutProperty('layout-test', 'visibility'),
      'none',
      'initial visibility is none',
    );

    state.layerOptions = {
      ...state.layerOptions,
      layout: { visibility: 'visible' },
    };
    await settled();

    assert.strictEqual(
      map?.getLayoutProperty('layout-test', 'visibility'),
      'visible',
      'visibility updated to visible',
    );
  });

  test('it updates paint properties', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.layerOptions = {
      id: 'paint-test',
      type: 'circle',
      paint: { 'circle-color': 'white' },
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{state.layerOptions}}>
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.deepEqual(
      map?.getPaintProperty('paint-test', 'circle-color'),
      'white',
      'initial color',
    );

    state.layerOptions = {
      ...state.layerOptions,
      paint: { 'circle-color': 'black' },
    };
    await settled();

    assert.deepEqual(
      map?.getPaintProperty('paint-test', 'circle-color'),
      'black',
      'color updated',
    );
  });

  test('it passes and updates filter', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.layerOptions = {
      id: 'filter-test',
      type: 'circle',
      filter: ['==', '$type', 'Point'],
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{state.layerOptions}}>
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.deepEqual(
      map?.getFilter('filter-test'),
      ['==', '$type', 'Point'],
      'filter was set',
    );

    state.layerOptions = {
      ...state.layerOptions,
      filter: ['!=', '$type', 'LineString'],
    };
    await settled();

    assert.deepEqual(
      map?.getFilter('filter-test'),
      ['!=', '$type', 'LineString'],
      'filter was updated',
    );

    // Clear the filter
    state.layerOptions = {
      ...state.layerOptions,
      filter: undefined,
    };
    await settled();

    assert.strictEqual(
      map?.getFilter('filter-test'),
      undefined,
      'filter was cleared',
    );
  });

  test('it updates minzoom and maxzoom', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.layerOptions = {
      id: 'zoom-test',
      type: 'circle',
      minzoom: 5,
      maxzoom: 10,
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{state.layerOptions}}>
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    // Verify initial minzoom/maxzoom were passed through
    const layer = map?.getLayer('zoom-test');
    assert.strictEqual(layer?.minzoom, 5, 'initial minzoom is 5');
    assert.strictEqual(layer?.maxzoom, 10, 'initial maxzoom is 10');

    const setZoomSpy = sinon.spy(map!, 'setLayerZoomRange');

    state.layerOptions = { ...state.layerOptions, minzoom: 2, maxzoom: 15 };
    await settled();

    assert.true(setZoomSpy.called, 'setLayerZoomRange called on update');
    assert.strictEqual(
      setZoomSpy.firstCall.args[0],
      'zoom-test',
      'setLayerZoomRange called with correct layerId',
    );
    assert.strictEqual(setZoomSpy.firstCall.args[1], 2, 'minzoom updated');
    assert.strictEqual(setZoomSpy.firstCall.args[2], 15, 'maxzoom updated');
  });

  test('it uses a provided layer id', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer
              @options={{hash id="my-custom-id" type="circle"}}
              as |layer|
            >
              <span data-test-layer-id>{{layer.id}}</span>
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-layer-id]'), { timeout: 10000 });
    assert.dom('[data-test-layer-id]').hasText('my-custom-id');
    assert.ok(map?.getLayer('my-custom-id'), 'layer exists with provided id');
  });

  test('it passes through other layer options like metadata and source-layer', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    const layerOptions = {
      id: 'passthrough-test',
      type: 'circle' as const,
      metadata: { author: 'test' },
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{layerOptions}}>
              <span data-test-loaded />
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    const layer = map?.getLayer('passthrough-test');
    assert.ok(layer, 'layer exists');
    assert.deepEqual(
      (layer as { metadata?: unknown })?.metadata,
      { author: 'test' },
      'metadata passed through',
    );
  });

  test('it yields the layer id', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="src"
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer
              @options={{hash id="yielded-id" type="circle"}}
              as |layer|
            >
              <span data-test-id>{{layer.id}}</span>
            </source.layer>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-id]'), { timeout: 10000 });
    assert.dom('[data-test-id]').hasText('yielded-id');
  });
});
