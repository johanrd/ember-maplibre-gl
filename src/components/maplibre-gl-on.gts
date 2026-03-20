// app/components/maplibre-gl-on.gts
import { isPresent } from '@ember/utils';
import { resource, resourceFactory } from 'ember-resources';
import { assert } from '@ember/debug';

import type {
  Listener,
  Map as MaplibreMap,
  MapLayerEventType,
} from 'maplibre-gl';
import type { TOC } from '@ember/component/template-only';

/** Minimal interface for any object that supports on/off event binding */
interface EventTarget {
  on(...args: unknown[]): unknown;
  off(...args: unknown[]): unknown;
}

interface Args {
  event: string;
  action: (...args: unknown[]) => void;
  eventSource?: EventTarget;
  layerId?: string;
}

export function mapOn(
  event: string,
  action: (...args: unknown[]) => void,
  eventSource?: EventTarget,
  layerId?: string,
) {
  assert(
    'maplibre-gl-event requires event to be a string',
    typeof event === 'string',
  );
  assert('maplibre-gl-event requires an eventSource', isPresent(eventSource));
  assert('maplibre-gl-event requires an action', isPresent(action));

  return resource(({ on }) => {
    const boundHandler: Listener = (...args: unknown[]) => {
      action(...args);
    };

    if ('on' in eventSource) {
      if (layerId) {
        (eventSource as MaplibreMap).on(
          event as keyof MapLayerEventType,
          layerId,
          boundHandler,
        );
      } else {
        eventSource.on(event, boundHandler);
      }
    }

    on.cleanup(() => {
      if ('off' in eventSource) {
        if (layerId) {
          (eventSource as MaplibreMap).off(
            event as keyof MapLayerEventType,
            layerId,
            boundHandler,
          );
        } else {
          eventSource.off(event, boundHandler);
        }
      }
    });
  });
}

resourceFactory(mapOn);

const MapLibreGLOn =
  // this should be a resource, and used as
  // {{map.on @event @action @layerId}} with prebound eventSource
  // but prebinding yielded resource arguments
  // does not seem to work without a {{#let}} wrapper
  // see https://discord.com/channels/480462759797063690/483601670685720591/1182683243959570493
  // https://github.com/emberjs/ember.js/issues/20589
  <template>
    {{mapOn @event @action @eventSource @layerId}}
  </template> satisfies TOC<Args>;

export default MapLibreGLOn;
