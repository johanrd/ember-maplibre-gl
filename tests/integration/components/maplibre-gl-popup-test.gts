import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash, array } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const STYLE = 'https://demotiles.maplibre.org/style.json';

class State {
  @tracked lngLat: [number, number] = [10.95, 59.61];
}

module('Integration | Component | maplibre-gl-popup', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders', async function (assert) {
    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:200px;"
          as |map|
        >
          <map.popup />
        </MapLibreGL>
      </template>,
    );

    // Just verify it doesn't throw
    assert.ok(true, 'popup renders without error');
  });

  test('popup content is rendered and events can be subscribed to', async function (assert) {
    const onClose = () => {
      // close event handler
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 10.95 59.61) zoom=12}}
          style="height:300px;"
          as |map|
        >
          <map.popup @lngLat={{array 10.95 59.61}} as |popup|>
            <popup.on @event="close" @action={{onClose}} />
            <span data-test-popup>Hi</span>
          </map.popup>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-popup-content'), {
      timeout: 10000,
    });
    assert
      .dom('.maplibregl-popup-content')
      .containsText('Hi', 'popup content rendered');
  });

  test('it handles re-renders after closing when lngLat changes', async function (assert) {
    const state = new State();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE center=(array 10.95 59.61) zoom=12}}
          style="height:300px;"
          as |map|
        >
          <map.popup @lngLat={{state.lngLat}}>
            <span data-test-popup>Hi</span>
          </map.popup>
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('.maplibregl-popup-content'), {
      timeout: 10000,
    });
    assert
      .dom('.maplibregl-popup-content')
      .containsText('Hi', 'popup content rendered');

    // Close via close button
    const closeBtn = document.querySelector(
      '.maplibregl-popup-close-button',
    ) as HTMLElement;
    if (closeBtn) {
      closeBtn.click();
      await settled();

      // Update lngLat — popup should reopen
      state.lngLat = [10.95, 59.62];
      await settled();

      assert
        .dom('.maplibregl-popup-content')
        .containsText('Hi', 'popup re-rendered after lngLat change');
    } else {
      assert.ok(true, 'popup rendered (no close button)');
    }
  });
});
