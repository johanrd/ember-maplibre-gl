import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import type { Map } from 'maplibre-gl';
import sinon from 'sinon';

const STYLE = { version: 8 as const, sources: {}, layers: [] };

const PNG_DATA_URL =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgqNn/HwAD9gI71V1GUAAAAABJRU5ErkJggg==';
const SVG_DATA_URL = `data:image/svg+xml,${encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>',
)}`;

class State {
  @tracked show = true;
}

module('Integration | Component | maplibre-gl-image', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(() => sinon.restore());

  test('it ignores undefined url', async function (assert) {
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
          <m.image @name="test" />
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    assert.false(
      map?.hasImage('test') ?? false,
      'no image added when url is undefined',
    );
  });

  test('it loads and adds the image to the map', async function (assert) {
    let loadImageSpy: sinon.SinonSpy | undefined;

    const imageUrl = '/assets/test-image.png';

    const setMap = (m: Map) => {
      loadImageSpy = sinon.spy(m, 'loadImage');
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.image @name="logo" @url={{imageUrl}} />
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    assert.true(loadImageSpy!.called, 'loadImage was called');
    assert.strictEqual(
      loadImageSpy!.firstCall.args[0],
      imageUrl,
      'loadImage called with correct URL',
    );
  });

  test('it removes the image on destroy', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const state = new State();

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          {{#if state.show}}
            <m.image @name="cleanup-test" @url="/fake-image.png" />
          {{/if}}
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    // Manually register the image so the destructor has something to clean up
    // (loadImage fails in test env since URL is fake)
    if (!map!.hasImage('cleanup-test')) {
      map!.addImage('cleanup-test', {
        width: 1,
        height: 1,
        data: new Uint8Array(4),
      });
    }

    const removeImageSpy = sinon.spy(map!, 'removeImage');

    state.show = false;
    await settled();

    assert.true(removeImageSpy.called, 'removeImage was called on destroy');
    assert.strictEqual(
      removeImageSpy.firstCall.args[0],
      'cleanup-test',
      'removes correct image name',
    );
  });

  test('it discards stale loads when url changes mid-flight', async function (assert) {
    let loadImageStub: sinon.SinonStub | undefined;
    let addImageStub: sinon.SinonStub | undefined;

    const setMap = (m: Map) => {
      loadImageStub = sinon.stub(m, 'loadImage');
      // Default: return a never-resolving promise (so calls don't crash)
      loadImageStub.returns(new Promise(() => {}));
      // Second call resolves immediately
      loadImageStub.onSecondCall().resolves({ data: new Image() });
      addImageStub = sinon.stub(m, 'addImage');
    };

    class UrlState {
      @tracked url = '/first.png';
    }
    const urlState = new UrlState();

    // Not awaited: the first load never resolves, so render() settles only
    // once the URL change below replaces it.
    const rendered = render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.image @name="stale-test" @url={{urlState.url}} />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => loadImageStub?.called, { timeout: 10000 });

    // Change URL while first load is still pending
    urlState.url = '/second.png';
    await rendered;

    assert.strictEqual(
      loadImageStub!.firstCall.args[0],
      '/first.png',
      'first loadImage called with first URL',
    );
    assert.strictEqual(
      loadImageStub!.secondCall.args[0],
      '/second.png',
      'second loadImage called with new URL',
    );

    // Second load resolves immediately; addImage should be called once
    assert.true(
      addImageStub!.calledOnce,
      'addImage called only once (stale first result discarded)',
    );
  });

  test('it does not add the image if component is destroyed before load completes', async function (assert) {
    type LoadImageResult = Awaited<ReturnType<Map['loadImage']>>;

    let loadImageStub: sinon.SinonStub | undefined;
    let addImageSpy: sinon.SinonSpy | undefined;
    let finishLoad: ((result: LoadImageResult) => void) | undefined;

    const setMap = (m: Map) => {
      // Hold the load open so it can be finished after the component is gone.
      loadImageStub = sinon.stub(m, 'loadImage').callsFake(
        () =>
          new Promise<LoadImageResult>((resolve) => {
            finishLoad = resolve;
          }),
      );
      addImageSpy = sinon.spy(m, 'addImage');
    };

    const state = new State();

    // Not awaited: the load is still open, so render() settles only once the
    // image component below is destroyed.
    const rendered = render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          {{#if state.show}}
            <m.image @name="destroy-before-load" @url="/slow-image.png" />
          {{/if}}
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => loadImageStub?.called, { timeout: 10000 });

    state.show = false;
    await rendered;

    // The load finishes after the component is destroyed.
    finishLoad!({ data: new Image() });
    await settled();

    assert.true(loadImageStub!.called, 'the load was started');
    assert.false(addImageSpy!.called, 'addImage not called after destroy');
  });

  test('it handles SVG images via Image element, not loadImage', async function (assert) {
    let loadImageSpy: sinon.SinonSpy | undefined;

    const setMap = (m: Map) => {
      loadImageSpy = sinon.spy(m, 'loadImage');
    };

    let receivedError: unknown;
    const onError = (err: unknown) => {
      receivedError = err;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.image @name="svg-test" @url="/test.svg" @onError={{onError}} />
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    assert.false(
      loadImageSpy!.called,
      'loadImage was NOT called (SVG uses Image element path)',
    );
    assert.true(receivedError instanceof Error, 'error is an Error instance');
    assert.strictEqual(
      (receivedError as Error).message,
      'Failed to load svg',
      'correct error message for failed SVG load',
    );
  });

  test('it discards stale loads when name changes with same url', async function (assert) {
    let addImageStub: sinon.SinonStub | undefined;
    let loadImageStub: sinon.SinonStub | undefined;

    const setMap = (m: Map) => {
      loadImageStub = sinon.stub(m, 'loadImage');
      // First call: never resolves (simulates slow load)
      loadImageStub.onFirstCall().returns(new Promise(() => {}));
      // Second call: resolves immediately
      loadImageStub.onSecondCall().resolves({ data: new Image() });
      addImageStub = sinon.stub(m, 'addImage');
    };

    class NameState {
      @tracked name = 'icon-a';
    }
    const nameState = new NameState();

    // Not awaited: the first load never resolves, so render() settles only
    // once the name change below replaces it.
    const rendered = render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.image @name={{nameState.name}} @url="/same-icon.png" />
        </MapLibreGL>
      </template>,
    );

    await waitUntil(() => loadImageStub?.called, { timeout: 10000 });

    // Change name while first load is still pending
    nameState.name = 'icon-b';
    await rendered;

    assert.true(
      addImageStub!.calledOnce,
      'addImage called only once (stale first result discarded)',
    );
    assert.strictEqual(
      addImageStub!.firstCall.args[0],
      'icon-b',
      'addImage called with the new name, not the stale one',
    );
  });

  test('it calls onError when image loading fails', async function (assert) {
    let receivedError: unknown;
    const onError = (err: unknown) => {
      receivedError = err;
    };

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          style="height:100px;"
          as |m|
        >
          <m.image
            @name="bad"
            @url="/nonexistent-12345.png"
            @onError={{onError}}
          />
          <span data-test-loaded />
        </MapLibreGL>
      </template>,
    );

    assert.ok(receivedError, 'onError was called with an error');
  });

  test('render() waits for raster and SVG images to be added', async function (assert) {
    let map: Map | undefined;
    const setMap = (m: Map) => {
      map = m;
    };
    const errors: unknown[] = [];
    const onError = (error: unknown) => errors.push(error);

    await render(
      <template>
        <MapLibreGL
          @initOptions={{hash style=STYLE}}
          @mapLoaded={{setMap}}
          style="height:100px;"
          as |m|
        >
          <m.image @name="png" @url={{PNG_DATA_URL}} @onError={{onError}} />
          <m.image
            @name="svg"
            @url={{SVG_DATA_URL}}
            @width={{10}}
            @height={{10}}
            @onError={{onError}}
          />
        </MapLibreGL>
      </template>,
    );

    assert.deepEqual(errors.map(String), [], 'no load errors');
    assert.true(map?.hasImage('png'), 'raster image added');
    assert.true(map?.hasImage('svg'), 'SVG image added');
  });
});
