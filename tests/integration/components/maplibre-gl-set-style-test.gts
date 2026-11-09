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

  test('a layer whose @before is missing from the new style is added on top', async function (assert) {
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
    } finally {
      console.warn = warn;
    }
  });

  module('pooling', function () {
    class FakeMap {
      static instances: FakeMap[] = [];
      listeners: Record<string, () => void> = {};
      _container: HTMLElement;
      _diffStyleRequest: AbortController | null = null;
      style = { _loaded: true };
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
      redraw() {}
      jumpTo() {}
      stop() {}
      triggerRepaint() {}
      remove() {
        this.removed = true;
      }
    }

    const MapLib = FakeMap as unknown as new (...args: unknown[]) => Map;

    class ShowState {
      @tracked show = true;
    }

    // Renders a pooled map, lets `act` change it, then unmounts it.
    async function renderAndUnmount(
      styleUrl: string,
      act: (map: FakeMap) => void,
    ) {
      FakeMap.instances = [];
      const state = new ShowState();
      const rendered = render(
        <template>
          {{#if state.show}}
            <MapLibreGL
              @initOptions={{hash style=styleUrl}}
              @reuseMaps={{true}}
              @mapLib={{MapLib}}
              style="height:100px;"
            />
          {{/if}}
        </template>,
      );
      await waitUntil(() => FakeMap.instances[0], { timeout: 10000 });
      const map = FakeMap.instances[0]!;
      map.fire('load');
      await rendered;

      act(map);
      await rerender();

      state.show = false;
      await settled();
      return map;
    }

    test('a map whose style was replaced is not pooled', async function (assert) {
      const map = await renderAndUnmount('/replaced.json', (m) => {
        // What MapLibre fires once setStyle() has loaded another style.
        m.style = { _loaded: true };
        m.fire('style.load');
      });
      assert.true(map.removed, 'the map was destroyed');
    });

    test('a map still fetching a diffed style is not pooled', async function (assert) {
      const map = await renderAndUnmount('/fetching.json', (m) => {
        m._diffStyleRequest = new AbortController();
      });
      assert.true(map.removed, 'the map was destroyed');
    });

    test('a map that rebuilt its own style after a context restore is pooled', async function (assert) {
      const map = await renderAndUnmount('/restored.json', (m) => {
        m.style = { _loaded: true };
        m.fire('webglcontextrestored');
        m.fire('style.load');
      });
      assert.false(map.removed, 'the map was pooled');
    });
  });
});
