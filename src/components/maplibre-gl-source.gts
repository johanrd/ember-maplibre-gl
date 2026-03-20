import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';

import MapLibreGLLayer from './maplibre-gl-layer.gts';
import MapLibreGL from './maplibre-gl.gts';

import { hash } from '@ember/helper';
import type { WithBoundArgs } from '@glint/template';
import {
  associateDestroyableChild,
  registerDestructor,
} from '@ember/destroyable';
import type { Map } from 'maplibre-gl';
import type Owner from '@ember/owner';

export interface MapLibreGLSourceArgs {
  map: Map;
  sourceId?: string;
  options: Parameters<Map['addSource']>['1'];
  parent?: MapLibreGL;
}

export interface MapLibreGLSourceSignature {
  Args: MapLibreGLSourceArgs;
  Blocks: {
    default: [
      {
        id: string;
        layer: WithBoundArgs<
          typeof MapLibreGLLayer,
          'map' | 'before' | 'sourceId'
        >;
      },
    ];
  };
}

/**
  Adds a data source to the map. The API matches the mapbox [source docs](https://www.mapbox.com/maplibre-gl-js/api/#sources).

  Example:
  ```hbs
    <MapLibreGL as |map|>
      <map.source @options={{hash
          type='geojson'
          data=(hash
            type='FeatureCollection'
            features=(array
              (hash
                type='Feature'
                geometry=(hash
                  type='Point'
                  coordinates=(array -96.7969879 32.7766642)
                )
              )
            )
          )
        }}>
      </map.source>
    </MapLibreGL>
  ```
*/

export default class MapLibreGLSource extends Component<MapLibreGLSourceSignature> {
  sourceId: string;

  constructor(owner: Owner, args: MapLibreGLSource['args']) {
    super(owner, args);
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

  updateSource = (options: MapLibreGLSource['args']['options']) => {
    const source = this.args.map.getSource(this.sourceId);
    if (!source) return;
    if (
      'setData' in source &&
      typeof source.setData === 'function' &&
      'data' in options &&
      options.data
    ) {
      if (
        typeof options.data === 'object' &&
        'type' in options.data &&
        options.data.type !== 'Feature' &&
        options.data.type !== 'FeatureCollection'
      ) {
        options.data = {
          type: 'Feature',
          properties: {},
          geometry: options.data,
        };
      }
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call -- duck-typed: verified via 'in' + typeof
      source.setData(options.data);
    }
    if (
      'setCoordinates' in source &&
      typeof source.setCoordinates === 'function' &&
      'coordinates' in options &&
      options.coordinates
    ) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setCoordinates(options.coordinates);
    }
    // Additional source update methods (react-map-gl pattern)
    if (
      'setUrl' in source &&
      typeof source.setUrl === 'function' &&
      'url' in options &&
      options.url
    ) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      source.setUrl(options.url);
    }
    if (
      'setTiles' in source &&
      typeof source.setTiles === 'function' &&
      'tiles' in options &&
      options.tiles
    ) {
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
