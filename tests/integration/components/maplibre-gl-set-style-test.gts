import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil } from '@ember/test-helpers';
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

    // Holds the style response back, so the renders below run while it loads.
    let release = () => {};
    const held = new Promise<void>((resolve) => (release = resolve));
    addProtocol('held', async () => {
      await held;
      return { data: OTHER_STYLE };
    });

    try {
      const loaded = new Promise((resolve) => map!.once('style.load', resolve));
      map!.setStyle('held://style', { diff: false });

      const updated: FeatureCollection = {
        type: 'FeatureCollection',
        features: [],
      };
      state.data = updated;
      state.showLayer = true;
      await settled();
      assert.false(
        map!.style._loaded,
        'that render ran while the style loaded',
      );

      release();
      await loaded;
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

      await setStyle(map!, STYLE, { diff: false });

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
      style = {};
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
      await settled();

      state.show = false;
      await settled();
      return map;
    }

    test('a map whose style was replaced is not pooled', async function (assert) {
      const map = await renderAndUnmount('/replaced.json', (m) => {
        // What MapLibre fires once setStyle() has loaded another style.
        m.style = {};
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
        m.style = {};
        m.fire('webglcontextrestored');
        m.fire('style.load');
      });
      assert.false(map.removed, 'the map was pooled');
    });
  });
});
