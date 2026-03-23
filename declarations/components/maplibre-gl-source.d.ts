import Component from '@glimmer/component';
import MapLibreGLLayer from './maplibre-gl-layer';
import type MapLibreGL from './maplibre-gl';
import type { WithBoundArgs } from '@glint/template';
import type { Map } from 'maplibre-gl';
import type Owner from '@ember/owner';
/**
 * Source specification passed to `map.addSource()` — defines the data backing a layer.
 *
 * Resolves to [SourceSpecification ↗](https://maplibre.org/maplibre-style-spec/sources/) from MapLibre, a union of GeoJSON, vector, raster,
 * raster-dem, image, and video source types.
 */
export type SourceOptions = Parameters<Map['addSource']>['1'];
/** Signature for {@link MapLibreGLSource}. */
export interface MapLibreGLSourceSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: Map;
        /** Custom source ID. Auto-generated if omitted. */
        sourceId?: string;
        /** Source specification matching MapLibre's `addSource` API (type, data, tiles, url, etc.). */
        options: SourceOptions;
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
                layer: WithBoundArgs<typeof MapLibreGLLayer, 'map' | 'sourceId' | 'parent'>;
            }
        ];
    };
}
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
export default class MapLibreGLSource extends Component<MapLibreGLSourceSignature> {
    /** @internal */
    sourceId: string;
    /** @internal */
    constructor(owner: Owner, args: MapLibreGLSource['args']);
    /** @internal */
    upsertSource: (options: MapLibreGLSource["args"]["options"]) => void;
}
//# sourceMappingURL=maplibre-gl-source.d.ts.map