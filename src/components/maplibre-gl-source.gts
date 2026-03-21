import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';

import MapLibreGLLayer from './maplibre-gl-layer.gts';
import type MapLibreGL from './maplibre-gl.gts';

import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import type { Map } from 'maplibre-gl';
import type Owner from '@ember/owner';

/** Signature for {@link MapLibreGLSource}. */
export interface MapLibreGLSourceSignature {
  Args: {
    /** The MapLibre map instance (pre-bound by parent). */
    map: Map;
    /** Custom source ID. Auto-generated if omitted. */
    sourceId?: string;
    /** Source specification matching MapLibre's `addSource` API (type, data, tiles, url, etc.). */
    options: Parameters<Map['addSource']>['1'];
    /** Parent component for destroyable association (pre-bound by parent). */
    parent?: MapLibreGL;
  };
  Blocks: {
    /** Yields the source ID and a pre-bound `layer` component scoped to this source. */
    default: [
      {
        /** The ID of this source on the map. */
        id: string;
        /** Add a layer that renders data from this source. Pre-bound with map, sourceId, and parent. */
        layer: WithBoundArgs<
          typeof MapLibreGLLayer,
          'map' | 'sourceId' | 'parent'
        >;
      },
    ];
  };
}

/**
 * Adds a data source to the map. Sources provide the data that layers render.
 * Supports GeoJSON, vector tiles, raster, image, and video source types.
 *
 * Yielded by `<MapLibreGL>` as `map.source`. Yields a pre-bound `layer` component
 * and the source ID. Updates to `@options` are applied reactively (e.g. setData for GeoJSON).
 *
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.source @options={{this.geojsonSource}} as |source|>
 *     <source.layer @options={{this.circleLayer}} />
 *   </map.source>
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLSource extends Component<MapLibreGLSourceSignature> {
  /** @internal */
  sourceId: string;
  private _prevData?: unknown;
  private _prevCoordinates?: unknown;
  private _prevUrl?: unknown;
  private _prevTiles?: unknown;

  /** @internal */
  constructor(owner: Owner, args: MapLibreGLSource['args']) {
    super(owner, args);

    assert(
      '`map` argument is required for `MapLibreGLSource` component',
      args.map,
    );

    this.sourceId = args.sourceId || guidFor(this);
    if (!args.map.getSource(this.sourceId)) {
      args.map.addSource(this.sourceId, args.options);
    } else {
      this.updateSource(args.options);
    }

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
  updateSource = (options: MapLibreGLSource['args']['options']) => {
    const source = this.args.map.getSource(this.sourceId);
    if (!source) return;
    if (
      'setData' in source &&
      typeof source.setData === 'function' &&
      'data' in options &&
      options.data &&
      options.data !== this._prevData
    ) {
      this._prevData = options.data;
      if (
        typeof options.data === 'object' &&
        'type' in options.data &&
        options.data.type !== 'Feature' &&
        options.data.type !== 'FeatureCollection'
      ) {
        const wrappedData = {
          type: 'Feature',
          properties: {},
          geometry: options.data,
        };
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call -- duck-typed: verified via 'in' + typeof
        source.setData(wrappedData);
      } else {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call -- duck-typed: verified via 'in' + typeof
        source.setData(options.data);
      }
    }
    if (
      'setCoordinates' in source &&
      typeof source.setCoordinates === 'function' &&
      'coordinates' in options &&
      options.coordinates &&
      options.coordinates !== this._prevCoordinates
    ) {
      this._prevCoordinates = options.coordinates;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setCoordinates(options.coordinates);
    }
    // Additional source update methods (react-map-gl pattern)
    if (
      'setUrl' in source &&
      typeof source.setUrl === 'function' &&
      'url' in options &&
      options.url &&
      options.url !== this._prevUrl
    ) {
      this._prevUrl = options.url;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setUrl(options.url);
    }
    if (
      'setTiles' in source &&
      typeof source.setTiles === 'function' &&
      'tiles' in options &&
      options.tiles &&
      options.tiles !== this._prevTiles
    ) {
      this._prevTiles = options.tiles;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setTiles(options.tiles);
    }
  };

  <template>
    {{this.updateSource @options}}

    {{yield
      (hash
        id=this.sourceId
        layer=(component
          MapLibreGLLayer map=@map sourceId=this.sourceId parent=this
        )
      )
    }}
  </template>
}
