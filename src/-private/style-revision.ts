import { tracked } from '@glimmer/tracking';
import type { Map as MaplibreMap } from 'maplibre-gl';

class Revision {
  @tracked value = 0;
}

const revisions = new WeakMap<MaplibreMap, Revision>();

function revisionOf(map: MaplibreMap) {
  let revision = revisions.get(map);
  if (!revision) revisions.set(map, (revision = new Revision()));
  return revision;
}

/** Read before any early return, so the upsert runs again after `map.setStyle()`. */
export function consumeStyleRevision(map: MaplibreMap) {
  return revisionOf(map).value;
}

export function bumpStyleRevision(map: MaplibreMap) {
  revisionOf(map).value++;
}

/**
 * False on a context-lost map (`style` is null) and while a style from
 * `setStyle()` loads, where adding a source or layer throws.
 */
export function isStyleLoaded(map: MaplibreMap) {
  return Boolean(map.style?._loaded);
}
