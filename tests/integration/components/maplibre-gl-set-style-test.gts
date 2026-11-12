import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, settled, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import { addProtocol, removeProtocol } from 'maplibre-gl';
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

// Holds the style response back until `release()` is called.
function holdStyle(style: StyleSpecification) {
  let release = () => {};
  const held = new Promise<void>((resolve) => (release = resolve));
  addProtocol('held', async () => {
    await held;
    return { data: style };
  });
  return release;
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

      map!.setStyle(OTHER_STYLE, { diff });
      await settled();

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

    map!.setStyle(OTHER_STYLE, { diff: false });
    await settled();

    const source = map!.getStyle().sources['points'];
    assert.deepEqual(
      source?.type === 'geojson' ? source.data : undefined,
      updated,
      'the re-added source has the current data, not the first',
    );
  });

  test('a render while the new style loads does not throw, and catches up once it has loaded', async function (assert) {
    class State {
      @tracked data: FeatureCollection = GEOJSON;
      @tracked showLayer = false;
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
            as |source|
          >
            {{#if state.showLayer}}
              <source.layer @options={{hash id="circles" type="circle"}} />
            {{/if}}
          </m.source>
        </MapLibreGL>
      </template>,
    );

    const release = holdStyle(OTHER_STYLE);

    try {
      map!.setStyle('held://style', { diff: false });

      const updated: FeatureCollection = {
        type: 'FeatureCollection',
        features: [],
      };
      state.data = updated;
      state.showLayer = true;
      await rerender();
      assert.strictEqual(
        map!.getStyle(),
        undefined,
        'that render ran while the style loaded',
      );

      release();
      await settled();

      const source = map!.getStyle().sources['points'];
      assert.deepEqual(
        source?.type === 'geojson' ? source.data : undefined,
        updated,
        'the source has the data set while the style loaded',
      );
      assert.ok(
        map!.getLayer('circles'),
        'the layer mounted while the style loaded is added',
      );
    } finally {
      removeProtocol('held');
    }
  });

  test('settled() waits for a diffed setStyle(url)', async function (assert) {
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
            @options={{hash type="geojson" data=GEOJSON}}
            as |source|
          >
            <source.layer @options={{hash id="circles" type="circle"}} />
          </m.source>
        </MapLibreGL>
      </template>,
    );

    const release = holdStyle(OTHER_STYLE);
    try {
      map!.setStyle('held://style');
      let isSettled = false;
      const settling = settled().then(() => (isSettled = true));

      await new Promise((resolve) => setTimeout(resolve, 100));
      assert.false(isSettled, 'settled() waits while the style is fetched');

      release();
      await settling;
      assert.ok(map!.getLayer('background'), 'the new style is in place');
      assert.ok(map!.getLayer('circles'), 'the layer is back');
    } finally {
      removeProtocol('held');
    }
  });

  test('settled() does not wait after a setStyle() that changes nothing', async function (assert) {
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
        />
      </template>,
    );

    const started = Date.now();
    map!.setStyle(STYLE);
    await settled();
    assert.true(Date.now() - started < 1000, 'settled() did not time out');
  });

  test('after a setStyle() that fails, settled() does not hang and the next style works', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const error = console.error;
    console.error = () => {};

    try {
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
              @options={{hash type="geojson" data=GEOJSON}}
              as |source|
            >
              <source.layer @options={{hash id="circles" type="circle"}} />
            </m.source>
          </MapLibreGL>
        </template>,
      );

      const started = Date.now();
      map!.setStyle('/missing-style.json', { diff: false });
      await settled();
      assert.true(Date.now() - started < 5000, 'settled() did not time out');

      map!.setStyle(OTHER_STYLE, { diff: false });
      await settled();
      assert.ok(map!.getLayer('background'), 'the next style is in place');
      assert.ok(map!.getLayer('circles'), 'the layer is back');
    } finally {
      console.error = error;
    }
  });

  test('@before can name a layer that comes later in the template', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const warn = console.warn;
    const warnings: unknown[] = [];
    console.warn = (...args: unknown[]) => warnings.push(args[0]);

    try {
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
              @options={{hash type="geojson" data=GEOJSON}}
              as |source|
            >
              <source.layer
                @options={{hash id="below" type="circle"}}
                @before="above"
              />
              <source.layer @options={{hash id="above" type="circle"}} />
            </m.source>
          </MapLibreGL>
        </template>,
      );
      assert.deepEqual(map!.getLayersOrder(), ['below', 'above']);

      map!.setStyle(OTHER_STYLE, { diff: false });
      await settled();
      assert.deepEqual(
        map!.getLayersOrder(),
        ['background', 'below', 'above'],
        'the order holds after setStyle',
      );
      assert.strictEqual(warnings.length, 0, 'nothing is reported');
    } finally {
      console.warn = warn;
    }
  });

  test('a layer whose @before is missing is added on top, and moves once that layer is added', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const warn = console.warn;
    const warnings: unknown[] = [];
    console.warn = (...args: unknown[]) => warnings.push(args[0]);

    try {
      await render(
        <template>
          <MapLibreGL
            @initOptions={{hash style=OTHER_STYLE}}
            @mapLoaded={{setMap}}
            style="height:100px;"
            as |m|
          >
            <m.source
              @sourceId="points"
              @options={{hash type="geojson" data=GEOJSON}}
              as |source|
            >
              <source.layer
                @options={{hash id="circles" type="circle"}}
                @before="background"
              />
            </m.source>
          </MapLibreGL>
        </template>,
      );

      assert.deepEqual(map!.getLayersOrder(), ['circles', 'background']);

      map!.setStyle(STYLE, { diff: false });
      await settled();

      assert.deepEqual(map!.getLayersOrder(), ['circles'], 'the layer is back');
      assert.true(
        warnings.some((w) => String(w).includes('"background"')),
        'the missing @before layer is reported',
      );

      // Added under the layer, so only a move puts it back on top of it.
      map!.addLayer(
        {
          id: 'background',
          type: 'background',
          paint: { 'background-color': '#000' },
        },
        'circles',
      );
      await waitUntil(() => map!.getLayersOrder()[0] === 'circles', {
        timeout: 5000,
      });
      assert.deepEqual(
        map!.getLayersOrder(),
        ['circles', 'background'],
        'the layer moves under @before once it is added',
      );
    } finally {
      console.warn = warn;
    }
  });

  module('pooling', function () {
    class FakeMap {
      static instances: FakeMap[] = [];
      listeners: Record<string, (() => void)[]> = {};
      _container: HTMLElement;
      _diffStyleRequest: AbortController | null = null;
      style = { _loaded: true, stylesheet: {} };
      styleList: unknown[] = [];
      removed = false;

      constructor(options: { container: HTMLElement }) {
        this._container = options.container;
        FakeMap.instances.push(this);
      }

      on(type: string, listener: () => void) {
        (this.listeners[type] ??= []).push(listener);
        return this;
      }
      once(type: string, listener: () => void) {
        return this.on(type, listener);
      }
      off() {
        return this;
      }
      fire(type: string) {
        for (const listener of this.listeners[type] ?? []) listener();
      }
      getStyle() {
        return {};
      }
      setStyle(style: unknown) {
        this.styleList.push(style);
        this.style = { _loaded: true, stylesheet: {} };
      }
      getContainer() {
        return this._container;
      }
      resize() {}
      redraw() {}
      jumpTo() {}
      stop() {}
      triggerRepaint() {}
      remove() {
        this.removed = true;
      }
    }

    class State {
      @tracked show = true;
      @tracked style = '/first.json';
    }

    // Renders a pooled map, lets `act` change it, unmounts it and mounts it with `nextStyle`.
    async function remount(
      nextStyle: string,
      act: (map: FakeMap) => void = () => {},
    ) {
      FakeMap.instances = [];
      // Its own class, so that it has its own pool.
      const MapLib = class extends FakeMap {} as unknown as new (
        ...args: unknown[]
      ) => Map;
      const state = new State();
      const rendered = render(
        <template>
          {{#if state.show}}
            <MapLibreGL
              @initOptions={{hash style=state.style}}
              @reuseMaps={{true}}
              @mapLib={{MapLib}}
              style="height:100px;"
            >
              <span data-test-block>loaded</span>
            </MapLibreGL>
          {{/if}}
        </template>,
      );
      await waitUntil(() => FakeMap.instances[0], { timeout: 10000 });
      const map = FakeMap.instances[0]!;
      map.fire('load');
      await rendered;
      act(map);

      state.show = false;
      await settled();
      state.style = nextStyle;
      state.show = true;
      await rerender();
      return map;
    }

    test('a reused map with the same style keeps it', async function (assert) {
      const map = await remount('/first.json');
      await settled();
      assert.strictEqual(FakeMap.instances.length, 1, 'no new map was built');
      assert.deepEqual(map.styleList, [], 'setStyle() was not called');
      assert.dom('[data-test-block]').exists();
    });

    test('a reused map gets another style, and renders once it has loaded', async function (assert) {
      const map = await remount('/second.json');
      assert.deepEqual(
        map.styleList,
        ['/second.json'],
        'the style was rebuilt',
      );
      assert.dom('[data-test-block]').doesNotExist('waits for the style');
      map.fire('style.load');
      await settled();
      assert.dom('[data-test-block]').exists();
    });

    test('a reused map that had map.setStyle() gets its initOptions.style back', async function (assert) {
      const map = await remount('/first.json', (m) =>
        m.setStyle('/other.json'),
      );
      assert.deepEqual(map.styleList, ['/other.json', '/first.json']);
      map.fire('style.load');
      await settled();
      assert.dom('[data-test-block]').exists();
    });
  });
});
