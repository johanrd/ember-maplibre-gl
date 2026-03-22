import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import type maplibregl from 'maplibre-gl';
import type { FilterSpecification, LayerSpecification } from 'maplibre-gl';
import { hash } from '@ember/helper';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import type MapLibreGLSource from './maplibre-gl-source.gts';
import type MapLibreGL from './maplibre-gl.gts';
import type Owner from '@ember/owner';

/** Signature for {@link MapLibreGLLayer}. */
export interface MapLibreGLLayerSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: maplibregl.Map;
    /** Source ID to render data from (pre-bound when used via `source.layer`). */
    sourceId: string;
    /** Layer specification (type, paint, layout, filter, etc.). The `id` and `source` are optional and auto-filled. */
    options: Omit<LayerSpecification, 'id'> & {
      id?: LayerSpecification['id'];
      source?: string;
    };
    /** Layer ID or position to insert this layer before in the stack. */
    before?: Parameters<maplibregl.Map['addLayer']>[1];
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
 * @example
 * ```gts
 * <map.source @options={{this.geojsonSource}} as |source|>
 *   <source.layer @options={{hash type="circle" paint=(hash circle-radius=6 circle-color="#007cbf")}} />
 * </map.source>
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

  /** @internal */
  upsertLayer = (options?: MapLibreGLLayerSignature['Args']['options']) => {
    if (typeof options !== 'object') return;

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
      return;
    }

    if (options.layout) {
      for (const k in options.layout) {
        this.args.map.setLayoutProperty(
          this.layerId,
          k,
          options.layout[k as keyof typeof options.layout],
        );
      }
    }

    if (options.paint) {
      for (const k in options.paint) {
        this.args.map.setPaintProperty(
          this.layerId,
          k,
          options.paint[k as keyof typeof options.paint],
        );
      }
    }

    if ('minzoom' in options || 'maxzoom' in options) {
      const minzoom =
        'minzoom' in options && options.minzoom != null ? options.minzoom : 0;
      const maxzoom =
        'maxzoom' in options && options.maxzoom != null ? options.maxzoom : 24;
      this.args.map.setLayerZoomRange(this.layerId, minzoom, maxzoom);
    }

    if ('filter' in options) {
      this.args.map.setFilter(
        this.layerId,
        options.filter as FilterSpecification,
      );
    }

    if (this.args.before !== this.prevBefore) {
      this.prevBefore = this.args.before;
      if (this.args.before !== undefined) {
        this.args.map.moveLayer(this.layerId, this.args.before);
      }
    }
  };

  <template>
    {{this.upsertLayer @options}}
    {{yield (hash id=this.layerId)}}
  </template>
}
