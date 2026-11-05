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

/**
 * Read by every component that adds something to the style (a source, a
 * layer, an image), so its upsert runs again after `map.setStyle()`. MapLibre
 * drops what was added at runtime when the style changes: a rebuilt style
 * starts empty, and a diffed one removes whatever the new style lacks.
 */
export function consumeStyleRevision(map: MaplibreMap) {
  return revisionOf(map).value;
}

/** Call when the map has loaded a style after its first one. */
export function bumpStyleRevision(map: MaplibreMap) {
  revisionOf(map).value++;
}
