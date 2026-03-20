import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { assert } from '@ember/debug';
import maplibregl, {
  type FilterSpecification,
  type LayerSpecification,
} from 'maplibre-gl';
import { hash } from '@ember/helper';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import MapLibreGLSource from './maplibre-gl-source.gts';
import type MapLibreGL from './maplibre-gl.gts';
import type Owner from '@ember/owner';

export interface MapLibreGLLayerArgs {
  map: maplibregl.Map;
  sourceId: string;
  options: Omit<LayerSpecification, 'id'> & {
    id?: LayerSpecification['id'];
    source?: string;
  };
  before?: Parameters<maplibregl.Map['addLayer']>[1];
  parent?: MapLibreGLSource | MapLibreGL;
}

export interface MapLibreGLLayerSignature {
  Args: MapLibreGLLayerArgs;
  Blocks: {
    default: [
      {
        id: string;
      },
    ];
  };
}

export default class MapLibreGLLayer extends Component<MapLibreGLLayerSignature> {
  layerId: string;

  constructor(owner: Owner, args: MapLibreGLLayerArgs) {
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

    const layerOptions = {
      ...this.args.options,
      id: this.layerId,
      type: this.args.options?.type ?? 'line',
      source: this.args.sourceId || this.args.options?.source,
    };

    // @ts-expect-error: However much we'd like to type this, it seems impossible to please both maplibre-gl and maplibre-gl types here
    args.map.addLayer(layerOptions, args.before);

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (args.map.getLayer(this.layerId))
          args.map?.removeLayer(this.layerId);
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  private prevOptions?: MapLibreGLLayerArgs['options'];
  private prevBefore?: MapLibreGLLayerArgs['before'];

  updateLayer = (options?: MapLibreGLLayerArgs['options']) => {
    if (typeof options !== 'object') return;

    const prev = this.prevOptions;
    this.prevOptions = options;

    if (options.layout) {
      for (const k in options.layout) {
        this.args.map.setLayoutProperty(
          this.layerId,
          k,
          options.layout[k as keyof typeof options.layout],
        );
      }
      // Reset removed layout properties (react-map-gl pattern)
      if (prev?.layout) {
        for (const k in prev.layout) {
          if (!(k in (options.layout ?? {}))) {
            this.args.map.setLayoutProperty(this.layerId, k, undefined);
          }
        }
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
      // Reset removed paint properties (react-map-gl pattern)
      if (prev?.paint) {
        for (const k in prev.paint) {
          if (!(k in (options.paint ?? {}))) {
            this.args.map.setPaintProperty(this.layerId, k, undefined);
          }
        }
      }
    }

    if (
      'minzoom' in options &&
      options.minzoom &&
      'maxzoom' in options &&
      options.maxzoom
    ) {
      this.args.map.setLayerZoomRange(
        this.layerId,
        options.minzoom,
        options.maxzoom,
      );
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
    {{this.updateLayer @options}}
    {{yield (hash id=this.layerId)}}
  </template>
}
