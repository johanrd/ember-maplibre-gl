import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import MapLibreGLLayer from './maplibre-gl-layer.js';
import { hash } from '@ember/helper';
import { associateDestroyableChild, registerDestructor } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/** Signature for {@link MapLibreGLSource}. */
/**
 * Adds a data source to the map. Sources provide the data that layers render.
 * Supports GeoJSON, vector tiles, raster, image, and video source types.
 *
 * Updates to `@options` are applied reactively (e.g. setData for GeoJSON).
 *
 * @access `<MapLibreGL>` as `map.source`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.source @options={{this.geojsonSource}} as |source|>
 *     <source.layer @options={{this.circleLayer}} />
 *   </map.source>
 * </MapLibreGL>
 * ```
 */
class MapLibreGLSource extends Component {
  /** @internal */sourceId;
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLSource` component', args.map);
    this.sourceId = args.sourceId || guidFor(this);
    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this.args.map.getSource(this.sourceId)) {
          this.args.map.removeSource(this.sourceId);
        }
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }
  /** @internal */
  upsertSource = options => {
    const source = this.args.map.getSource(this.sourceId);
    if (!source) {
      this.args.map.addSource(this.sourceId, options);
      return;
    }
    if ('setData' in source && typeof source.setData === 'function' && 'data' in options && options.data) {
      if (typeof options.data === 'object' && 'type' in options.data && options.data.type !== 'Feature' && options.data.type !== 'FeatureCollection') {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call -- duck-typed: verified via 'in' + typeof
        source.setData({
          type: 'Feature',
          properties: {},
          geometry: options.data
        });
      } else {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call -- duck-typed: verified via 'in' + typeof
        source.setData(options.data);
      }
    }
    if ('setCoordinates' in source && typeof source.setCoordinates === 'function' && 'coordinates' in options && options.coordinates) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setCoordinates(options.coordinates);
    }
    if ('setUrl' in source && typeof source.setUrl === 'function' && 'url' in options && options.url) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setUrl(options.url);
    }
    if ('setTiles' in source && typeof source.setTiles === 'function' && 'tiles' in options && options.tiles) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setTiles(options.tiles);
    }
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.upsertSource @options}}\n\n{{yield (hash id=this.sourceId layer=(component MapLibreGLLayer map=@map sourceId=this.sourceId parent=this))}}", {
      strictMode: true,
      scope: () => ({
        hash,
        MapLibreGLLayer
      })
    }), this);
  }
}

export { MapLibreGLSource as default };
//# sourceMappingURL=maplibre-gl-source.js.map
