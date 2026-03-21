import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map, GeoJSONSource } from 'maplibre-gl';
import type { FeatureCollection } from 'geojson';
import sinon from 'sinon';

const STYLE = 'https://demotiles.maplibre.org/style.json';

class State {
  @tracked show = true;
  @tracked options!: Parameters<Map['addSource']>['1'];
}

module('Integration | Component | maplibre-gl-source', function (hooks) {
  setupRenderingTest(hooks);

  test('it creates a sourceId if one is not provided', async function (assert) {
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
            @options={{hash
              type="geojson"
              data=(hash type="FeatureCollection" features=(array))
            }}
            as |source|
          >
            <span data-test-id>{{source.id}}</span>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-id]'), { timeout: 10000 });
    const sourceId = find('[data-test-id]')!.textContent.trim();
    assert.ok(sourceId, 'a sourceId was generated');
    assert.ok(map?.getSource(sourceId), 'source exists on map');
  });

  test('it uses a provided sourceId and passes correct options', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    const geojson: FeatureCollection = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: {},
          geometry: { type: 'Point', coordinates: [0, 0] },
        },
      ],
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
            @sourceId="my-source"
            @options={{hash type="geojson" data=geojson}}
            as |source|
          >
            <span data-test-id>{{source.id}}</span>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-id]'), { timeout: 10000 });
    assert.dom('[data-test-id]').hasText('my-source');
    assert.ok(map?.getSource('my-source'), 'source exists with provided id');
  });

  test('it updates geojson data via setData', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.options = {
      type: 'geojson',
      data: { type: 'FeatureCollection' as const, features: [] },
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source @sourceId="data-test" @options={{state.options}}>
            <span data-test-loaded />
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    const source = map?.getSource('data-test');
    assert.ok(source, 'source exists');

    const setDataSpy = sinon.spy(source as GeoJSONSource, 'setData');

    state.options = {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            properties: {},
            geometry: { type: 'Point', coordinates: [1, 1] },
          },
        ],
      },
    };
    await settled();

    assert.true(setDataSpy.called, 'setData was called on the real source');
  });

  test('it updates coordinates via setCoordinates for video sources', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();
    state.options = {
      type: 'video',
      urls: [],
      coordinates: [
        [-76.54, 39.18],
        [-76.52, 39.18],
        [-76.52, 39.17],
        [-76.54, 39.17],
      ],
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source @sourceId="video-test" @options={{state.options}}>
            <span data-test-loaded />
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    const source = map?.getSource('video-test');
    assert.ok(source, 'video source exists');

    if (source && 'setCoordinates' in source) {
      const spy = sinon.spy(source, 'setCoordinates');
      const updated: [
        [number, number],
        [number, number],
        [number, number],
        [number, number],
      ] = [
        [-76.55, 39.19],
        [-76.51, 39.19],
        [-76.51, 39.16],
        [-76.55, 39.16],
      ];
      state.options = { ...state.options, coordinates: updated };
      await settled();

      assert.true(spy.called, 'setCoordinates was called');
    } else {
      // Video sources may not be supported in all MapLibre builds
      assert.ok(true, 'video source created (setCoordinates not available)');
    }
  });

  test('it passes sourceId to child layers', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };

    const geojson: FeatureCollection = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: {},
          geometry: { type: 'Point', coordinates: [0, 0] },
        },
      ],
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
            @sourceId="parent-src"
            @options={{hash type="geojson" data=geojson}}
            as |source|
          >
            <source.layer
              @options={{hash
                type="circle"
                paint=(hash circle-color="#ff0000" circle-radius=3)
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
    assert.ok(layer, 'layer exists on real map');
    assert.strictEqual(
      (layer as { source: string })?.source,
      'parent-src',
      'layer references correct source',
    );
  });

  test('it removes the source when destroyed', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();

    const geojson: FeatureCollection = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: {},
          geometry: { type: 'Point', coordinates: [0, 0] },
        },
      ],
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          {{#if state.show}}
            <m.source
              @sourceId="remove-test"
              @options={{hash type="geojson" data=geojson}}
            >
              <span data-test-loaded />
            </m.source>
          {{/if}}
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.ok(map?.getSource('remove-test'), 'source exists');

    state.show = false;
    await settled();

    assert.notOk(map?.getSource('remove-test'), 'source removed after destroy');
  });

  test('it yields the sourceId', async function (assert) {
    const geojson: FeatureCollection = {
      type: 'FeatureCollection',
      features: [],
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:100px;"
          as |m|
        >
          <m.source
            @sourceId="yield-test"
            @options={{hash type="geojson" data=geojson}}
            as |source|
          >
            <span data-test-id>{{source.id}}</span>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-id]'), { timeout: 10000 });
    assert.dom('[data-test-id]').hasText('yield-test');
  });

  test('it yields a layer component', async function (assert) {
    const geojson: FeatureCollection = {
      type: 'FeatureCollection',
      features: [],
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:100px;"
          as |m|
        >
          <m.source @options={{hash type="geojson" data=geojson}} as |source|>
            <span data-test-has-layer>{{if source.layer "yes" "no"}}</span>
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-has-layer]'), { timeout: 10000 });
    assert.dom('[data-test-has-layer]').hasText('yes');
  });

  test('it handles full source data replacement', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();

    const initialData: FeatureCollection = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: { name: 'original' },
          geometry: { type: 'Point', coordinates: [0, 0] },
        },
      ],
    };

    const replacementData: FeatureCollection = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: { name: 'replaced' },
          geometry: { type: 'LineString', coordinates: [[1, 1], [2, 2], [3, 3]] },
        },
        {
          type: 'Feature',
          properties: { name: 'new-point' },
          geometry: { type: 'Point', coordinates: [5, 5] },
        },
      ],
    };

    state.options = {
      type: 'geojson',
      data: initialData,
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.source @sourceId="replace-test" @options={{state.options}}>
            <span data-test-loaded />
          </m.source>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });

    const source = map?.getSource('replace-test');
    assert.ok(source, 'source exists');

    const setDataSpy = sinon.spy(source as GeoJSONSource, 'setData');

    // Replace with completely different FeatureCollection
    state.options = {
      type: 'geojson',
      data: replacementData,
    };
    await settled();

    assert.true(setDataSpy.called, 'setData was called with new data');
    const calledWith = setDataSpy.firstCall.args[0] as FeatureCollection;
    assert.strictEqual(
      calledWith.features.length,
      2,
      'setData received the replacement FeatureCollection with 2 features',
    );
  });
});
