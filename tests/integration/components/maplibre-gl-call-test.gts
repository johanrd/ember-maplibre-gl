import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
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
});
