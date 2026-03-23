import { isPresent } from '@ember/utils';
import { resourceFactory, resource } from 'ember-resources';
import { assert } from '@ember/debug';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';
import templateOnly from '@ember/component/template-only';

/**
 * Resource-based event binding helper. Registers an event listener and automatically
 * removes it on cleanup. Used internally by the `MapLibreGLOn` template component.
 */
function mapOn(event,
// eslint-disable-next-line @typescript-eslint/no-explicit-any
action, eventSource, layerId) {
  assert('maplibre-gl-event requires event to be a string', typeof event === 'string');
  assert('maplibre-gl-event requires an eventSource', isPresent(eventSource));
  assert('maplibre-gl-event requires an action', isPresent(action));
  return resource(({
    on
  }) => {
    const boundHandler = (...args) => {
      action(...args);
    };
    if (layerId) {
      eventSource.on(event, layerId, boundHandler);
    } else {
      eventSource.on(event, boundHandler);
    }
    on.cleanup(() => {
      if (layerId) {
        eventSource.off(event, layerId, boundHandler);
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
 * @access `<MapLibreGL>` as `map.on`, `<map.marker>` as `marker.on`, `<map.popup>` as `popup.on`, `<map.control>` as `control.on`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.on @event="click" @action={{this.handleClick}} />
 *   <map.on @event="click" @layerId="my-layer" @action={{this.handleLayerClick}} />
 * </MapLibreGL>
 * ```
 */
const MapLibreGLOn = // this should be a resource, and used as
// {{map.on @event @action @layerId}} with prebound eventSource
// but prebinding yielded resource arguments
// does not seem to work without a {{#let}} wrapper
// see https://discord.com/channels/480462759797063690/483601670685720591/1182683243959570493
// https://github.com/emberjs/ember.js/issues/20589
setComponentTemplate(precompileTemplate("{{mapOn @event @action @eventSource @layerId}}", {
  strictMode: true,
  scope: () => ({
    mapOn
  })
}), templateOnly());

export { MapLibreGLOn as default, mapOn };
//# sourceMappingURL=maplibre-gl-on.js.map
