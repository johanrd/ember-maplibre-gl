import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map, StyleSpecification } from 'maplibre-gl';
import type { FeatureCollection } from 'geojson';

const STYLE: StyleSpecification = { version: 8, sources: {}, layers: [] };
const OTHER_STYLE: StyleSpecification = {
  version: 8,
  sources: {},
  layers: [
    {
      id: 'background',
      type: 'background',
      paint: { 'background-color': '#000' },
    },
  ],
};

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgqNn/HwAD9gI71V1GUAAAAABJRU5ErkJggg==';

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

// The components add their content again in the render that follows the event.
async function setStyle(map: Map, ...args: Parameters<Map['setStyle']>) {
  const loaded = new Promise((resolve) => map.once('style.load', resolve));
  map.setStyle(...args);
  await loaded;
  await settled();
}

module('Integration | Component | maplibre-gl | setStyle', function (hooks) {
  setupRenderingTest(hooks);

  for (const diff of [false, true]) {
    test(`sources, layers and images are added again after setStyle (diff: ${diff})`, async function (assert) {
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
            <m.image @name="dot" @url={{PNG_DATA_URL}} />
            <m.source
              @sourceId="points"
              @options={{hash type="geojson" data=GEOJSON}}
              as |source|
            >
              <source.layer @options={{hash id="circles" type="circle"}} />
              <source.layer
                @options={{hash id="below" type="circle"}}
                @before="circles"
              />
            </m.source>
          </MapLibreGL>
        </template>,
      );

      assert.ok(map!.getLayer('circles'), 'layer is on the first style');
      assert.true(map!.hasImage('dot'), 'image is on the first style');

      await setStyle(map!, OTHER_STYLE, { diff });
      await waitUntil(() => map!.hasImage('dot'), { timeout: 5000 });

      assert.ok(map!.getLayer('background'), 'the new style is in place');
      assert.ok(map!.getSource('points'), 'source was added again');
      assert.ok(map!.getLayer('circles'), 'layer was added again');
      assert.deepEqual(
        map!.getLayersOrder(),
        ['background', 'below', 'circles'],
        '@before is honoured when the layers come back',
      );
      assert.true(map!.hasImage('dot'), 'image was added again');
    });
  }

  test('a source keeps the data it had when the style is replaced', async function (assert) {
    class State {
      @tracked data: FeatureCollection = GEOJSON;
    }
    const state = new State();
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
            @sourceId="points"
            @options={{hash type="geojson" data=state.data}}
          />
        </MapLibreGL>
      </template>,
    );

    const updated: FeatureCollection = {
      type: 'FeatureCollection',
      features: [],
    };
    state.data = updated;
    await settled();

    await setStyle(map!, OTHER_STYLE, { diff: false });

    const source = map!.getStyle().sources['points'];
    assert.deepEqual(
      source?.type === 'geojson' ? source.data : undefined,
      updated,
      'the re-added source has the current data, not the first',
    );
  });

  test('a map whose style was replaced is not pooled under its first style', async function (assert) {
    class FakeMap {
      static instances: FakeMap[] = [];
      listeners: Record<string, () => void> = {};
      _container: HTMLElement;
      removed = false;

      constructor(options: { container: HTMLElement }) {
        this._container = options.container;
        FakeMap.instances.push(this);
      }

      on(type: string, listener: () => void) {
        this.listeners[type] = listener;
        return this;
      }
      off() {
        return this;
      }
      fire(type: string) {
        this.listeners[type]?.();
      }
      getStyle() {
        return {};
      }
      getContainer() {
        return this._container;
      }
      resize() {}
      jumpTo() {}
      stop() {}
      triggerRepaint() {}
      remove() {
        this.removed = true;
      }
    }

    const MapLib = FakeMap as unknown as new (...args: unknown[]) => Map;
    const FIRST_STYLE = '/first-style.json';

    class ShowState {
      @tracked show = true;
    }
    const state = new ShowState();

    const rendered = render(
      <template>
        {{#if state.show}}
          <MapLibreGL
            @initOptions={{hash style=FIRST_STYLE}}
            @reuseMaps={{true}}
            @mapLib={{MapLib}}
            style="height:100px;"
          />
        {{/if}}
      </template>,
    );

    await waitUntil(() => FakeMap.instances[0], { timeout: 10000 });
    FakeMap.instances[0]!.fire('load');
    await rendered;

    // What MapLibre fires once setStyle() has loaded another style.
    FakeMap.instances[0]!.fire('style.load');
    await settled();

    state.show = false;
    await settled();
    assert.true(FakeMap.instances[0]!.removed, 'the map was destroyed');

    state.show = true;
    await waitUntil(() => FakeMap.instances[1], { timeout: 10000 });
    FakeMap.instances[1]!.fire('load');
    await settled();

    assert.strictEqual(FakeMap.instances.length, 2, 'a new map was built');

    state.show = false;
    await settled();
  });
});
