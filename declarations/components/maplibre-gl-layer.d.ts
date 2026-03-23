import Component from '@glimmer/component';
import type maplibregl from 'maplibre-gl';
import type { LayerSpecification } from 'maplibre-gl';
import type MapLibreGLSource from './maplibre-gl-source';
import type MapLibreGL from './maplibre-gl';
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
        map: maplibregl.Map;
        /** Source ID to render data from (pre-bound when used via `source.layer`). */
        sourceId: string;
        /** Layer specification (type, paint, layout, filter, etc.). The `id` and `source` are optional and auto-filled. */
        options: LayerOptions;
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
            }
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
    constructor(owner: Owner, args: MapLibreGLLayerSignature['Args']);
    private prevBefore?;
    /** @internal */
    upsertLayer: (options?: MapLibreGLLayerSignature["Args"]["options"]) => void;
}
//# sourceMappingURL=maplibre-gl-layer.d.ts.map