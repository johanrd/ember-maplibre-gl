import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import type {
  Map as MaplibreMap,
  FilterSpecification,
  LayerSpecification,
} from 'maplibre-gl';
import { hash } from '@ember/helper';
import {
  associateDestroyableChild,
  isDestroyed,
  isDestroying,
  registerDestructor,
} from '@ember/destroyable';
import type MapLibreGLSource from './maplibre-gl-source.gts';
import type MapLibreGL from './maplibre-gl.gts';
import type Owner from '@ember/owner';
import {
  consumeStyleRevision,
  isStyleLoaded,
} from '../-private/style-revision.ts';

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

/**
 * The paint or layout properties that differ between two renders. A property
 * the new object no longer has comes back as `undefined`, which resets it to
 * the style-spec default.
 */
function changedProperties<T extends object>(prev?: T, next?: T) {
  const keys = new Set([
    ...Object.keys(prev ?? {}),
    ...Object.keys(next ?? {}),
  ]) as Set<keyof T>;
  return [...keys]
    .filter((key) => next?.[key] !== prev?.[key])
    .map((key) => [key, next?.[key] as T[keyof T]] as const);
}

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
 * paint, layout, filter, zoom range, and position when args change. A paint or
 * layout property that is no longer passed goes back to its default.
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

  // @before may name a layer rendered later in the template, or one the new style lacks:
  // add on top, then move once the render is done.
  private existingBefore() {
    const { before, map } = this.args;
    if (!before || map.getLayer(before)) return before;
    queueMicrotask(() => this.moveBefore(before));
    return undefined;
  }

  private moveBefore(before: string) {
    const { map } = this.args;
    if (isDestroying(this) || isDestroyed(this) || this.args.before !== before)
      return;
    if (!isStyleLoaded(map) || !map.getLayer(this.layerId)) return;
    if (map.getLayer(before)) {
      map.moveLayer(this.layerId, before);
    } else {
      console.warn(
        `ember-maplibre-gl: layer "${this.layerId}" is on top, because @before layer "${before}" is not in the style.`,
      );
    }
  }

  /** @internal */
  upsertLayer = (options?: MapLibreGLLayerSignature['Args']['options']) => {
    if (typeof options !== 'object') return;

    consumeStyleRevision(this.args.map);
    if (!isStyleLoaded(this.args.map)) return;

    if (!this.args.map.getLayer(this.layerId)) {
      const layerOptions = {
        ...options,
        id: this.layerId,
        type: options.type ?? 'line',
        source: this.args.sourceId || options.source,
      };

      // @ts-expect-error — LayerSpecification is a discriminated union on `type`;
      // TypeScript can't narrow a spread of the full union to a single variant.
      this.args.map.addLayer(layerOptions, this.existingBefore());
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

    if (options.layout !== this.prevLayout) {
      for (const [key, value] of changedProperties(
        this.prevLayout,
        options.layout,
      )) {
        this.args.map.setLayoutProperty(this.layerId, key, value);
      }
      this.prevLayout = options.layout;
    }

    if (options.paint !== this.prevPaint) {
      for (const [key, value] of changedProperties(
        this.prevPaint,
        options.paint,
      )) {
        this.args.map.setPaintProperty(this.layerId, key, value);
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
      this.args.map.moveLayer(this.layerId, this.existingBefore());
    }
  };

  <template>
    {{this.upsertLayer @options}}
    {{yield (hash id=this.layerId)}}
  </template>
}
