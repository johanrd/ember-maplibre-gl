import { tracked } from '@glimmer/tracking';
import { macroCondition, isDevelopingApp } from '@embroider/macros';
import { register, type Waiter } from '@ember/test-waiters';
import type { Map as MaplibreMap, Style } from 'maplibre-gl';
import { WAIT_TIMEOUT_MS } from './wait.ts';

class StyleState {
  @tracked revision = 0;
  // A style that fired 'error' before it loaded: it never will, so the waiter stops on it.
  failedStyle?: Style;
  busySince?: number;
  timedOut = false;
}

const states = new WeakMap<MaplibreMap, StyleState>();
const mountedMaps = new Set<MaplibreMap>();

function stateOf(map: MaplibreMap) {
  let state = states.get(map);
  if (!state) states.set(map, (state = new StyleState()));
  return state;
}

/** Read before any early return, so the upsert runs again after `map.setStyle()`. */
export function consumeStyleRevision(map: MaplibreMap) {
  return stateOf(map).revision;
}

/** False on a context-lost map, and while a style from `setStyle()` loads. Same check as react-map-gl. */
export function isStyleLoaded(map: MaplibreMap) {
  return Boolean(map.style?._loaded);
}

export function markStyleFailed(map: MaplibreMap) {
  if (map.style && !map.style._loaded) stateOf(map).failedStyle = map.style;
}

export function bumpStyleRevision(map: MaplibreMap) {
  stateOf(map).revision++;
}

// A diffed setStyle(url) fires nothing until its fetch is done, so only the request shows it.
function isBusy(map: MaplibreMap) {
  if (map._diffStyleRequest) return true;
  return (
    Boolean(map.style) &&
    !map.style._loaded &&
    map.style !== stateOf(map).failedStyle
  );
}

// Polled by settled(): it ends with the style, and also after a diff that changes nothing.
const styleWaiter: Waiter = {
  name: 'ember-maplibre-gl:set-style',
  waitUntil() {
    const now = Date.now();
    let idle = true;
    for (const map of mountedMaps) {
      const state = stateOf(map);
      if (!isBusy(map)) {
        state.busySince = undefined;
        state.timedOut = false;
        continue;
      }
      state.busySince ??= now;
      if (now - state.busySince < WAIT_TIMEOUT_MS) {
        idle = false;
      } else if (!state.timedOut) {
        state.timedOut = true;
        console.warn(
          `ember-maplibre-gl: a style did not load within ${WAIT_TIMEOUT_MS}ms, ` +
            `so anything waiting on it carries on without it.`,
        );
      }
    }
    return idle;
  },
  debugInfo() {
    return [...mountedMaps]
      .filter(isBusy)
      .map(() => ({ label: 'a style that loads', stack: undefined }));
  },
};

/** Lets settled() wait for the map's `setStyle()` calls. Returns the function that stops it. */
export function waitForStyleChanges(map: MaplibreMap) {
  if (macroCondition(!isDevelopingApp())) return () => {};
  register(styleWaiter);
  mountedMaps.add(map);
  return () => mountedMaps.delete(map);
}
