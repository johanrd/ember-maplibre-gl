import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { tracked, cached } from '@glimmer/tracking';
import MapLibreGLCall from 'ember-maplibre-gl/components/maplibre-gl-call';
import sinon from 'sinon';
import { type MapInstance } from 'ember-maplibre-gl/components/maplibre-gl-call';

module('Integration | Component | maplibre-gl-call', function (hooks) {
  setupRenderingTest(hooks);

  test('it calls the specified function on the object', async function (assert) {
    const flyToStub = sinon.stub().returns('result');
    const obj = { flyTo: flyToStub } as unknown as MapInstance;

    const args = [{ center: [0, 0], zoom: 5 }];

    await render(
      <template>
        <MapLibreGLCall
          @obj={{obj}}
          @func="flyTo"
          @positionalArguments={{args}}
        />
      </template>,
    );

    assert.true(flyToStub.called, 'function was called');
    assert.deepEqual(
      flyToStub.firstCall.args,
      [{ center: [0, 0], zoom: 5 }],
      'function was called with correct arguments',
    );
  });

  test('it binds the correct this context when calling the function', async function (assert) {
    const flyToFn = sinon.stub();
    const obj = { flyTo: flyToFn } as unknown as MapInstance;

    const args = [{ center: [0, 0] }];

    await render(
      <template>
        <MapLibreGLCall
          @obj={{obj}}
          @func="flyTo"
          @positionalArguments={{args}}
        />
      </template>,
    );

    assert.true(flyToFn.calledOnce, 'function was called');
    assert.true(
      flyToFn.calledOn(obj),
      'function was called with the object as this context',
    );
  });

  test('it passes the return value to onResp', async function (assert) {
    assert.expect(1);

    const getZoomStub = sinon.stub().returns(10);
    const obj = { getZoom: getZoomStub } as unknown as MapInstance;

    let receivedResult: unknown;

    const onResp = (result: unknown) => {
      receivedResult = result;
    };

    const emptyArgs: unknown[] = [];

    await render(
      <template>
        <MapLibreGLCall
          @obj={{obj}}
          @func="getZoom"
          @positionalArguments={{emptyArgs}}
          @onResp={{onResp}}
        />
      </template>,
    );

    assert.strictEqual(receivedResult, 10, 'onResp receives the return value');
  });

  // Pins the reactivity contract documented on the component. The caller here is
  // as disciplined as a caller can be: both arguments are the same object on
  // every render, and the getter that produces them is `@cached`. The method
  // still runs again, because Glimmer propagates by tag and not by value.
  test('it re-invokes on a tag bump even when every argument is the same object', async function (assert) {
    const flyToStub = sinon.stub();
    const obj = { flyTo: flyToStub } as unknown as MapInstance;

    const STABLE_BOUNDS = [10, 59, 11, 60];
    const STABLE_OPTIONS = { duration: 0 };

    class State {
      @tracked bump = 0;

      // Consumes the tracked state, then returns the identical array every time.
      @cached
      get bounds() {
        void this.bump;
        return STABLE_BOUNDS;
      }
    }
    const state = new State();

    await render(
      <template>
        <MapLibreGLCall
          @obj={{obj}}
          @func="flyTo"
          @positionalArguments={{array state.bounds STABLE_OPTIONS}}
        />
      </template>,
    );

    assert.strictEqual(flyToStub.callCount, 1, 'called once on first render');

    state.bump++;
    await settled();

    assert.strictEqual(
      flyToStub.callCount,
      2,
      'a tag bump re-invokes the method although no argument value changed',
    );
    assert.strictEqual(
      flyToStub.secondCall.args[0],
      flyToStub.firstCall.args[0],
      'the bounds argument is the identical object across both calls',
    );
    assert.strictEqual(
      flyToStub.secondCall.args[1],
      flyToStub.firstCall.args[1],
      'the options argument is the identical object across both calls',
    );
  });
});
