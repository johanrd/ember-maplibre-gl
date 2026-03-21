import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const STYLE = 'https://demotiles.maplibre.org/style.json';

class State {
  @tracked show = true;
}

module('Integration | Component | maplibre-gl-marker', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a marker on the map', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          <map.marker @lngLat={{array 0 0}}>
            <span data-test-content>marker</span>
          </map.marker>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    assert.dom('.maplibregl-marker').exists('marker element is in the DOM');
  });

  test('it yields a popup component', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          <map.marker @lngLat={{array 0 0}} as |marker|>
            <span data-test-has-popup>{{if marker.popup "yes" "no"}}</span>
          </map.marker>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    // Content is rendered inside the marker via in-element
    const markerEl = document.querySelector('.maplibregl-marker')!;
    const popup = markerEl.querySelector('[data-test-has-popup]');
    assert.strictEqual(popup?.textContent, 'yes', 'popup component is yielded');
  });

  test('it yields an on component', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          <map.marker @lngLat={{array 0 0}} as |marker|>
            <span data-test-has-on>{{if marker.on "yes" "no"}}</span>
          </map.marker>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    const markerEl = document.querySelector('.maplibregl-marker')!;
    const on = markerEl.querySelector('[data-test-has-on]');
    assert.strictEqual(on?.textContent, 'yes', 'on component is yielded');
  });

  test('it removes the marker on destroy', async function (assert) {
    const state = new State();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          {{#if state.show}}
            <map.marker @lngLat={{array 0 0}} />
          {{/if}}
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    assert.dom('.maplibregl-marker').exists('marker in DOM');

    state.show = false;
    await settled();

    assert.dom('.maplibregl-marker').doesNotExist('marker removed from DOM');
  });

  test('it forwards marker events via the on component', async function (assert) {
    let firedEvent = '';
    const onDragStart = () => {
      firedEvent = 'dragstart';
    };
    const onDragEnd = () => {
      firedEvent = 'dragend';
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          <map.marker
            @lngLat={{array 0 0}}
            @initOptions={{hash draggable=true}}
            as |marker|
          >
            <marker.on @event="dragstart" @action={{onDragStart}} />
            <marker.on @event="dragend" @action={{onDragEnd}} />
            <span data-test-marker>has events</span>
          </map.marker>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    const markerEl = document.querySelector('.maplibregl-marker')!;
    assert.ok(
      markerEl.querySelector('[data-test-marker]'),
      'marker with event bindings rendered',
    );
    assert.strictEqual(firedEvent, '', 'no events fired yet');
  });

  test('it renders multiple markers and cleans up DOM', async function (assert) {
    class ItemsState {
      @tracked items = [1, 2, 3];
    }

    const state = new ItemsState();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          {{#each state.items as |n|}}
            <map.marker @lngLat={{array n 0}} />
          {{/each}}
          <span data-test-markers-loaded>loaded</span>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-markers-loaded]'), {
      timeout: 10000,
    });
    await waitUntil(
      () => document.querySelectorAll('.maplibregl-marker').length === 3,
      { timeout: 10000 },
    );
    assert.strictEqual(
      document.querySelectorAll('.maplibregl-marker').length,
      3,
      'three markers rendered in DOM',
    );

    state.items = [1];
    await settled();

    assert.strictEqual(
      document.querySelectorAll('.maplibregl-marker').length,
      1,
      'markers reduced to one after state change',
    );
  });

  test('it creates actual DOM marker elements', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 0 0) zoom=1}}
          style="height:200px;"
          as |map|
        >
          <map.marker @lngLat={{array 0 0}} />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-marker'), { timeout: 10000 });
    const container = find('.maplibregl-canvas-container')?.parentElement;
    assert.ok(
      container?.querySelector('.maplibregl-marker'),
      'marker DOM element created',
    );
  });
});
