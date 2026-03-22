import { isPresent } from '@ember/utils';
import { resource, resourceFactory } from 'ember-resources';
import { assert } from '@ember/debug';

import type {
  Evented,
  Listener,
  Map as MaplibreMap,
  MapLayerEventType,
} from 'maplibre-gl';
import type { TOC } from '@ember/component/template-only';

/** Args for the `MapLibreGLOn` template-only component. */
interface Args {
  /** The event name to listen for (e.g. "click", "moveend", "dragend"). */
  event: string;
  /** Callback invoked when the event fires. Receives the MapLibre event object. */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any -- event handlers receive library-specific event types
  action: (...args: any[]) => void;
  /** The object to listen on — map, marker, popup, or control (pre-bound by parent). */
  eventSource?: Evented;
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
  eventSource?: Evented,
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

    if (layerId) {
      (eventSource as MaplibreMap).on(
        event as keyof MapLayerEventType,
        layerId,
        boundHandler,
      );
    } else {
      eventSource.on(event, boundHandler);
    }

    on.cleanup(() => {
      if (layerId) {
        (eventSource as MaplibreMap).off(
          event as keyof MapLayerEventType,
          layerId,
          boundHandler,
        );
      } else {
        eventSource.off(event, boundHandler);
      }
    });
  });
}

resourceFactory(mapOn);

/**
 * Declaratively binds an event listener to a map, marker, or popup. Automatically
 * cleans up the listener when the component is destroyed.
 *
 * When used with `@layerId`, the event only fires for features in that layer.
 *
 * @access `<MapLibreGL>` as `map.on`, `<map.marker>` as `marker.on`, `<map.popup>` as `popup.on`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.on @event="click" @action={{this.handleClick}} />
 *   <map.on @event="click" @layerId="my-layer" @action={{this.handleLayerClick}} />
 * </MapLibreGL>
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
