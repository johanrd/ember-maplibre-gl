import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import { hash } from '@ember/helper';
import { associateDestroyableChild, registerDestructor } from '@ember/destroyable';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/** Signature for {@link MapLibreGLLayer}. */
/**
 * Adds a rendering layer to the map. Layers define how source data is styled and displayed.
 *
 * Usually used via `source.layer` (pre-bound to the source), but can also be used
 * directly via `map.layer` with an explicit source reference. Reactively updates
 * paint, layout, filter, zoom range, and position when args change.
 *
 * @access `<map.source>` as `source.layer`, or `<MapLibreGL>` as `map.layer`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.source @options={{this.geojsonSource}} as |source|>
 *     <source.layer @options={{hash type="circle" paint=(hash circle-radius=6 circle-color="#007cbf")}} />
 *   </map.source>
 * </MapLibreGL>
 * ```
 */
class MapLibreGLLayer extends Component {
  /** @internal */layerId;
  /** @internal */
  constructor(owner, args) {
    super(owner, args);
    assert('`map` argument is required for `MapLibreGLLayer` component', args.map);
    assert('`options` argument is required for `MapLibreGLLayer` component', args.options);
    this.layerId = args.options?.id ?? guidFor(this);
    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this.args.map.getLayer(this.layerId)) this.args.map?.removeLayer(this.layerId);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }
  prevBefore;
  /** @internal */
  upsertLayer = options => {
    if (typeof options !== 'object') return;
    if (!this.args.map.getLayer(this.layerId)) {
      const layerOptions = {
        ...options,
        id: this.layerId,
        type: options.type ?? 'line',
        source: this.args.sourceId || options.source
      };
      // @ts-expect-error — LayerSpecification is a discriminated union on `type`;
      // TypeScript can't narrow a spread of the full union to a single variant.
      this.args.map.addLayer(layerOptions, this.args.before);
      this.prevBefore = this.args.before;
      return;
    }
    if (options.layout) {
      for (const k in options.layout) {
        this.args.map.setLayoutProperty(this.layerId, k, options.layout[k]);
      }
    }
    if (options.paint) {
      for (const k in options.paint) {
        this.args.map.setPaintProperty(this.layerId, k, options.paint[k]);
      }
    }
    if ('minzoom' in options || 'maxzoom' in options) {
      const minzoom = 'minzoom' in options && options.minzoom != null ? options.minzoom : 0;
      const maxzoom = 'maxzoom' in options && options.maxzoom != null ? options.maxzoom : 24;
      this.args.map.setLayerZoomRange(this.layerId, minzoom, maxzoom);
    }
    if ('filter' in options) {
      this.args.map.setFilter(this.layerId, options.filter);
    }
    if (this.args.before !== this.prevBefore) {
      this.prevBefore = this.args.before;
      this.args.map.moveLayer(this.layerId, this.args.before);
    }
  };
  static {
    setComponentTemplate(precompileTemplate("{{this.upsertLayer @options}}\n{{yield (hash id=this.layerId)}}", {
      strictMode: true,
      scope: () => ({
        hash
      })
    }), this);
  }
}

export { MapLibreGLLayer as default };
//# sourceMappingURL=maplibre-gl-layer.js.map
