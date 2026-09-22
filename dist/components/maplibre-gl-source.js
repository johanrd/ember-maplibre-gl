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
  prevData;
  prevCoordinates;
  prevUrl;
  prevTiles;
  /** @internal */
  upsertSource = options => {
    // MapLibre sets `map.style = null` on WebGL context loss (then fires
    // 'webglcontextlost') and on remove(), even though it types `style` as non-null.
    // getSource/addSource dereference it, so a render against a context-lost map throws
    // "Cannot read properties of null (reading 'getSource')". The destructor above
    // already guards for this; the render-time upsert must too. Self-healing: once the
    // context is restored MapLibre rebuilds the style and a later render re-runs this.
    if (!this.args.map.style) return;
    const source = this.args.map.getSource(this.sourceId);
    if (!source) {
      this.args.map.addSource(this.sourceId, options);
      // Seed prev-refs so the first revalidation after creation is a no-op
      // when the consumer's @options reference is stable.
      if ('data' in options) this.prevData = options.data;
      if ('coordinates' in options) this.prevCoordinates = options.coordinates;
      if ('url' in options) this.prevUrl = options.url;
      if ('tiles' in options) this.prevTiles = options.tiles;
      return;
    }
    if ('setData' in source && typeof source.setData === 'function' && 'data' in options && options.data && options.data !== this.prevData) {
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
      this.prevData = options.data;
    }
    if ('setCoordinates' in source && typeof source.setCoordinates === 'function' && 'coordinates' in options && options.coordinates && options.coordinates !== this.prevCoordinates) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setCoordinates(options.coordinates);
      this.prevCoordinates = options.coordinates;
    }
    if ('setUrl' in source && typeof source.setUrl === 'function' && 'url' in options && options.url && options.url !== this.prevUrl) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setUrl(options.url);
      this.prevUrl = options.url;
    }
    if ('setTiles' in source && typeof source.setTiles === 'function' && 'tiles' in options && options.tiles && options.tiles !== this.prevTiles) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setTiles(options.tiles);
      this.prevTiles = options.tiles;
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
