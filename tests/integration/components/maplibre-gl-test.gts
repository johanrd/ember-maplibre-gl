import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, settled, waitUntil } from '@ember/test-helpers';
import { getPendingWaiterState } from '@ember/test-waiters';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map } from 'maplibre-gl';
import mapboxgl from 'mapbox-gl';
import sinon from 'sinon';

const STYLE = { version: 8 as const, sources: {}, layers: [] };
const STYLE_URL = 'https://demotiles.maplibre.org/style.json';

module('Integration | Component | maplibre-gl', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(() => sinon.restore());

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

    assert.ok(firstMap, 'first map instance captured');

    const firstCanvas = firstMap!.getCanvas();

    // Destroy
    state.show = false;
    await settled();

    // Re-render
    state.show = true;
    await settled();

    assert.ok(secondMap, 'second map instance captured');
    assert.strictEqual(
      secondMap!.getCanvas(),
      firstCanvas,
      'same WebGL canvas reused across remounts',
    );
  });

  test('a reused map renders the block while its tiles are still loading', async function (assert) {
    // A pooled map comes back with its style already parsed, so MapLibre never
    // fires 'style.load' for it again, and isStyleLoaded() stays false while
    // tiles are in flight. Waiting on that event here would wait forever.
    class PooledMap {
      static instances: PooledMap[] = [];
      listeners: Record<string, () => void> = {};
      _container: HTMLElement;
      styleLoaded = true;

      constructor(options: { container: HTMLElement }) {
        this._container = options.container;
        PooledMap.instances.push(this);
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
      isStyleLoaded() {
        return this.styleLoaded;
      }
      resize() {}
      jumpTo() {}
      stop() {}
      triggerRepaint() {}
      remove() {}
    }

    const MapLib = PooledMap as unknown as new (...args: unknown[]) => Map;
    const POOLED_STYLE = '/pooled-style.json';

    class ShowState {
      @tracked show = true;
    }
    const state = new ShowState();

    // Not awaited: this fake only loads when the test says so.
    const rendered = render(
      <template>
        {{#if state.show}}
          <MapLibreGL
            @initOptions={{hash style=POOLED_STYLE}}
            @reuseMaps={{true}}
            @mapLib={{MapLib}}
            style="height:200px;"
          >
            <span data-test-pooled>loaded</span>
          </MapLibreGL>
        {{/if}}
      </template>,
    );

    await waitUntil(() => PooledMap.instances[0], { timeout: 10000 });
    PooledMap.instances[0]!.fire('load');
    await rendered;
    assert.dom('[data-test-pooled]').exists('first mount rendered the block');

    // Pool it, then remount with tiles still loading.
    state.show = false;
    await settled();
    PooledMap.instances[0]!.styleLoaded = false;

    state.show = true;
    await settled();

    assert.strictEqual(
      PooledMap.instances.length,
      1,
      'the pooled map was reused, not rebuilt',
    );
    assert.dom('[data-test-pooled]').exists('remount rendered the block');
  });

  test('pooling on destroy halts animations and disconnects the ResizeObserver', async function (assert) {
    class ShowState {
      @tracked show = true;
    }

    let firstMap: Map | undefined;
    const state = new ShowState();
    const captureMap = (m: Map) => {
      if (!firstMap) firstMap = m;
    };

    await render(
      <template>
        {{#if state.show}}
          <MapLibreGL
            @initOptions={{hash style=STYLE_URL center=(array 0 0) zoom=1}}
            @reuseMaps={{true}}
            @mapLoaded={{captureMap}}
            style="height:200px;"
          >
            <span data-test-pool-loaded>loaded</span>
          </MapLibreGL>
        {{/if}}
      </template>,
    );

    assert.ok(firstMap, 'map instance captured');

    type MapInternals = { _resizeObserver?: ResizeObserver };
    const resizeObserver = (firstMap as unknown as MapInternals)
      ._resizeObserver;
    assert.ok(resizeObserver, 'map has a _resizeObserver private');

    const stopSpy = sinon.spy(firstMap!, 'stop');
    const disconnectSpy = sinon.spy(resizeObserver!, 'disconnect');

    state.show = false;
    await settled();

    assert.strictEqual(
      stopSpy.callCount,
      1,
      'map.stop() called once before pooling',
    );
    assert.strictEqual(
      disconnectSpy.callCount,
      1,
      'ResizeObserver.disconnect() called once before pooling',
    );
  });

  module('test waiter', function (hooks) {
    const isWaiting = () =>
      'ember-maplibre-gl:map-load' in getPendingWaiterState().waiters;

    type Listener = (event?: unknown) => void;

    // Lets a test decide when, and whether, 'load' and 'error' fire.
    class ManualMap {
      static instance?: ManualMap;
      styleLoaded = false;
      listeners: Record<string, Listener> = {};

      constructor() {
        ManualMap.instance = this;
      }

      on(type: string, listener: Listener) {
        this.listeners[type] = listener;
        return this;
      }

      off() {
        return this;
      }

      getStyle() {
        return this.styleLoaded ? {} : undefined;
      }

      remove() {}

      fire(type: string, event?: unknown) {
        this.listeners[type]?.(event);
      }
    }

    const ManualMapLib = ManualMap as unknown as new (
      ...args: unknown[]
    ) => Map;

    hooks.beforeEach(function () {
      ManualMap.instance = undefined;
    });

    test('render() waits for the map to load', async function (assert) {
      await render(
        <template>
          <MapLibreGL @initOptions={{hash style=STYLE}} style="height:200px;">
            <span data-test-loaded>loaded</span>
          </MapLibreGL>
        </template>,
      );

      assert.dom('[data-test-loaded]').exists();
    });

    test('render() settles when the style fails to load', async function (assert) {
      await render(
        <template>
          <MapLibreGL
            @initOptions={{hash style="/nonexistent-style.json"}}
            style="height:200px;"
          >
            <:default>
              <span data-test-loaded />
            </:default>
            <:error>
              <span data-test-error />
            </:error>
          </MapLibreGL>
        </template>,
      );

      assert.dom('[data-test-error]').exists();
      assert.dom('[data-test-loaded]').doesNotExist();
    });

    test('an error after the style has loaded does not end the wait', async function (assert) {
      const rendered = render(
        <template>
          <MapLibreGL
            @initOptions={{hash style=STYLE}}
            @mapLib={{ManualMapLib}}
            style="height:200px;"
          >
            <span data-test-loaded>loaded</span>
          </MapLibreGL>
        </template>,
      );

      await waitUntil(() => ManualMap.instance, { timeout: 10000 });
      const map = ManualMap.instance!;
      assert.true(isWaiting(), 'waiting before load');

      map.styleLoaded = true;
      map.fire('error', { error: new Error('Tile failed') });
      assert.true(isWaiting(), 'still waiting after a tile error');

      map.fire('load');
      await rendered;
      assert.false(isWaiting(), 'wait ends on load');
      assert.dom('[data-test-loaded]').exists();
    });

    test('destroying the map before it loads ends the wait', async function (assert) {
      class ShowState {
        @tracked show = true;
      }
      const state = new ShowState();

      const rendered = render(
        <template>
          {{#if state.show}}
            <MapLibreGL
              @initOptions={{hash style=STYLE}}
              @mapLib={{ManualMapLib}}
              style="height:200px;"
            />
          {{/if}}
        </template>,
      );

      await waitUntil(() => ManualMap.instance, { timeout: 10000 });
      assert.true(isWaiting(), 'waiting before load');

      state.show = false;
      await rerender();
      assert.false(isWaiting(), 'wait ends when the component is destroyed');
      await rendered;
    });
  });
});
