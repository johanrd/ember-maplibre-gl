import { isPresent } from '@ember/utils';
import { resource, resourceFactory } from 'ember-resources';
import { assert } from '@ember/debug';

import type {
  Listener,
  Map as MaplibreMap,
  MapLayerEventType,
} from 'maplibre-gl';
import type { TOC } from '@ember/component/template-only';

/** Minimal interface for any object that supports on/off event binding. */
interface EventTarget {
  on(...args: unknown[]): unknown;
  off(...args: unknown[]): unknown;
}

/** Args for the `MapLibreGLOn` template-only component. */
interface Args {
  /** The event name to listen for (e.g. "click", "moveend", "dragend"). */
  event: string;
  /** Callback invoked when the event fires. Receives the MapLibre event object. */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any -- event handlers receive library-specific event types
  action: (...args: any[]) => void;
  /** The object to listen on — map, marker, or popup (pre-bound by parent). */
  eventSource?: EventTarget;
  /** Optional layer ID to scope map events to features in a specific layer. */
  layerId?: string;
}

/**
 * Resource-based event binding helper. Registers an event listener and automatically
 * removes it on cleanup. Used internally by the `MapLibreGLOn` template component.
 */
export function mapOn(
  event: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  action: (...args: any[]) => void,
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

/**
 * Declaratively binds an event listener to a map, marker, or popup. Automatically
 * cleans up the listener when the component is destroyed.
 *
 * Yielded by `<MapLibreGL>` as `map.on`, by `<marker>` as `marker.on`, and by
 * `<popup>` as `popup.on`. The `eventSource` is pre-bound by the parent.
 *
 * When used with `@layerId`, the event only fires for features in that layer.
 *
 * @example
 * ```gts
 * <map.on @event="click" @action={{this.handleClick}} />
 * <map.on @event="click" @layerId="my-layer" @action={{this.handleLayerClick}} />
 * ```
 */
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
