import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import MapLibreGLOn from 'ember-maplibre-gl/components/maplibre-gl-on';

class State {
  @tracked show = true;
}

module('Integration | Component | maplibre-gl-on', function (hooks) {
  setupRenderingTest(hooks);

  test('it subscribes to the event on the event source', async function (assert) {
    const done = assert.async();

    const event = { type: 'zoom' };

    const eventSource = {
      on(eventName: string, cb: (ev: unknown) => void) {
        assert.strictEqual(eventName, 'zoom', 'subscribes to event name');
        setTimeout(() => cb(event), 0);
      },
      off() {},
    };

    const onEvent = (ev: unknown) => {
      assert.strictEqual(ev, event, 'sends event to the action');
      done();
    };

    await render(
      <template>
        <MapLibreGLOn
          @event="zoom"
          @action={{onEvent}}
          @eventSource={{eventSource}}
        />
      </template>,
    );
  });

  test('it takes a layerId to target', async function (assert) {
    assert.expect(5);
    const done = assert.async();

    const event = { type: 'click' };

    const eventSource = {
      on(eventName: string, layerId: string, cb: (ev: unknown) => void) {
        assert.strictEqual(eventName, 'click', 'subscribes to event name');
        assert.strictEqual(layerId, 'my-layer', 'passes on layer');
        setTimeout(() => cb(event), 0);
      },
      off(eventName: string, layerId: string) {
        assert.strictEqual(eventName, 'click', 'unsubscribes to event name');
        assert.strictEqual(layerId, 'my-layer', 'passes on layer');
      },
    };

    const onEvent = (ev: unknown) => {
      assert.strictEqual(ev, event, 'sends event to the action');
      done();
    };

    await render(
      <template>
        <MapLibreGLOn
          @event="click"
          @layerId="my-layer"
          @action={{onEvent}}
          @eventSource={{eventSource}}
        />
      </template>,
    );
  });

  test('it cleans up the event listener on destroy', async function (assert) {
    assert.expect(2);

    const eventSource = {
      on(eventName: string) {
        assert.strictEqual(eventName, 'move', 'subscribes to event');
      },
      off(eventName: string) {
        assert.strictEqual(
          eventName,
          'move',
          'unsubscribes from event on destroy',
        );
      },
    };

    const onEvent = () => {};
    const state = new State();

    await render(
      <template>
        {{#if state.show}}
          <MapLibreGLOn
            @event="move"
            @action={{onEvent}}
            @eventSource={{eventSource}}
          />
        {{/if}}
      </template>,
    );

    state.show = false;
    await settled();
  });
});
