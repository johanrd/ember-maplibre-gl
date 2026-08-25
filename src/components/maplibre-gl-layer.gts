import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import type {
  Map as MaplibreMap,
  FilterSpecification,
  LayerSpecification,
} from 'maplibre-gl';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import type MapLibreGLSource from './maplibre-gl-source.gts';
import type MapLibreGL from './maplibre-gl.gts';
import type Owner from '@ember/owner';

/**
 * Layer options with optional `id` and `source` (auto-filled by the component).
 *
 * Accepts any MapLibre [LayerSpecification ↗](https://maplibre.org/maplibre-style-spec/layers/)
 * (fill, line, circle, symbol, etc.) but makes `id` optional since the component generates one.
 */
export type LayerOptions = Omit<LayerSpecification, 'id'> & {
  id?: LayerSpecification['id'];
  source?: string;
};

/** Signature for {@link MapLibreGLLayer}. */
export interface MapLibreGLLayerSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: MaplibreMap;
    /** Source ID to render data from (pre-bound when used via `source.layer`). */
    sourceId: string;
    /** Layer specification (type, paint, layout, filter, etc.). The `id` and `source` are optional and auto-filled. */
    options: LayerOptions;
    /** Layer ID or position to insert this layer before in the stack. */
    before?: Parameters<MaplibreMap['addLayer']>[1];
    /** Parent component for destroyable association (pre-bound by parent). */
    parent?: MapLibreGLSource | MapLibreGL;
  };
  Blocks: {
    /** Yields the layer's ID, useful for event binding or querying features. */
    default: [
      {
        /** The ID of this layer on the map. */
        id: string;
      },
    ];
  };
}

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
export default class MapLibreGLLayer extends Component<MapLibreGLLayerSignature> {
  /** @internal */
  layerId: string;

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLLayerSignature['Args']) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLLayer` component',
      args.map,
    );
    assert(
      '`options` argument is required for `MapLibreGLLayer` component',
      args.options,
    );

    this.layerId = args.options?.id ?? guidFor(this);

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this.args.map.getLayer(this.layerId))
          this.args.map?.removeLayer(this.layerId);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  private prevBefore?: MapLibreGLLayerSignature['Args']['before'];
  private prevLayout?: LayerOptions['layout'];
  private prevPaint?: LayerOptions['paint'];
  private prevFilter?: FilterSpecification;
  private prevMinzoom?: number;
  private prevMaxzoom?: number;

  /** @internal */
  upsertLayer = (options?: MapLibreGLLayerSignature['Args']['options']) => {
    if (typeof options !== 'object') return;

    // MapLibre sets `map.style = null` on WebGL context loss (then fires
    // 'webglcontextlost') and on remove(), even though it types `style` as non-null.
    // getLayer/addLayer dereference it, so a render against a context-lost map throws
    // "Cannot read properties of null (reading 'getLayer')". The destructor above
    // already guards for this; the render-time upsert must too. Self-healing: once the
    // context is restored MapLibre rebuilds the style and a later render re-runs this.
    if (!this.args.map.style) return;

    if (!this.args.map.getLayer(this.layerId)) {
      const layerOptions = {
        ...options,
        id: this.layerId,
        type: options.type ?? 'line',
        source: this.args.sourceId || options.source,
      };

      // @ts-expect-error — LayerSpecification is a discriminated union on `type`;
      // TypeScript can't narrow a spread of the full union to a single variant.
      this.args.map.addLayer(layerOptions, this.args.before);
      this.prevBefore = this.args.before;
      this.prevLayout = options.layout;
      this.prevPaint = options.paint;
      this.prevFilter =
        'filter' in options
          ? (options.filter as FilterSpecification | undefined)
          : undefined;
      this.prevMinzoom =
        'minzoom' in options && options.minzoom != null ? options.minzoom : 0;
      this.prevMaxzoom =
        'maxzoom' in options && options.maxzoom != null ? options.maxzoom : 24;
      return;
    }

    if (options.layout && options.layout !== this.prevLayout) {
      const prev = this.prevLayout;
      for (const k in options.layout) {
        const key = k as keyof typeof options.layout;
        const next = options.layout[key];
        if (next !== prev?.[key]) {
          this.args.map.setLayoutProperty(this.layerId, key, next);
        }
      }
      this.prevLayout = options.layout;
    }

    if (options.paint && options.paint !== this.prevPaint) {
      const prev = this.prevPaint;
      for (const k in options.paint) {
        const key = k as keyof typeof options.paint;
        const next = options.paint[key];
        if (next !== prev?.[key]) {
          this.args.map.setPaintProperty(this.layerId, key, next);
        }
      }
      this.prevPaint = options.paint;
    }

    if ('minzoom' in options || 'maxzoom' in options) {
      const minzoom =
        'minzoom' in options && options.minzoom != null ? options.minzoom : 0;
      const maxzoom =
        'maxzoom' in options && options.maxzoom != null ? options.maxzoom : 24;
      if (minzoom !== this.prevMinzoom || maxzoom !== this.prevMaxzoom) {
        this.args.map.setLayerZoomRange(this.layerId, minzoom, maxzoom);
        this.prevMinzoom = minzoom;
        this.prevMaxzoom = maxzoom;
      }
    }

    if ('filter' in options && options.filter !== this.prevFilter) {
      const filter = options.filter as FilterSpecification | undefined;
      this.args.map.setFilter(this.layerId, filter);
      this.prevFilter = filter;
    }

    if (this.args.before !== this.prevBefore) {
      this.prevBefore = this.args.before;
      this.args.map.moveLayer(this.layerId, this.args.before);
    }
  };

  <template>
    {{this.upsertLayer @options}}
    {{yield (hash id=this.layerId)}}
  </template>
}
