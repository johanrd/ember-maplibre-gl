import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil, find } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { NavigationControl } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const STYLE = 'https://demotiles.maplibre.org/style.json';

class State {
  @tracked show = true;
}

module('Integration | Component | maplibre-gl-control', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a control with position', async function (assert) {
    const nav = new NavigationControl();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:200px;"
          as |map|
        >
          <map.control @control={{nav}} @position="top-right" />
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert
      .dom('.maplibregl-ctrl-zoom-in')
      .exists('navigation control rendered in DOM');
  });

  test('it removes the control on destroy', async function (assert) {
    const nav = new NavigationControl();
    const state = new State();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:200px;"
          as |map|
        >
          {{#if state.show}}
            <map.control @control={{nav}} @position="top-right" />
          {{/if}}
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => find('[data-test-loaded]'), { timeout: 10000 });
    assert.dom('.maplibregl-ctrl-zoom-in').exists('control rendered');

    state.show = false;
    await settled();

    assert
      .dom('.maplibregl-ctrl-zoom-in')
      .doesNotExist('control removed from DOM');
  });
});
