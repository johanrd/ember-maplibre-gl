import Component from '@glimmer/component';
import type MapLibreGL from './maplibre-gl';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';
/**
 * Options passed to MapLibre's [map.addImage ↗](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/#addimage).
 *
 * Supports `pixelRatio` (for HiDPI images) and `sdf` (to enable runtime recoloring).
 *
 */
export type ImageOptions = Parameters<maplibregl.Map['addImage']>['2'];
/** Signature for {@link MapLibreGLImage}. */
export interface MapLibreGLImageSignature {
    Args: {
        /** The MapLibre map instance (pre-bound by parent). */
        map: maplibregl.Map;
        /** URL of the image to load. Supports PNG, JPEG, and SVG formats. */
        url?: Parameters<maplibregl.Map['loadImage']>['0'];
        /** Name to register the image under. Use this name in symbol layer `icon-image`. */
        name: Parameters<maplibregl.Map['addImage']>['0'];
        /** Image options (pixelRatio, sdf) passed to `map.addImage`. */
        options?: ImageOptions;
        /** Explicit width for SVG images (ignored for raster formats). */
        width?: HTMLImageElement['width'];
        /** Explicit height for SVG images (ignored for raster formats). */
        height?: HTMLImageElement['height'];
        /** Called when the image has been loaded and added to the map. */
        onLoad?: () => void;
        /** Called if the image fails to load. */
        onError?: (err: unknown) => void;
        /** Parent component for destroyable association (pre-bound by parent). */
        parent?: MapLibreGL;
    };
}
/** Error thrown when an SVG image fails to load. Contains the original load event. */
export declare class SvgLoadError extends Error {
    event: Event | string;
    constructor(message: string, event: Event | string);
}
/**
 * Loads an image from a URL and registers it on the map for use in symbol layers.
 * Handles both raster (PNG/JPEG via `map.loadImage`) and SVG images (via `<img>`).
 * The image is removed from the map when the component is destroyed.
 *
 * @access `<MapLibreGL>` as `map.image`
 * @example
 * ```gts
 * <MapLibreGL @initOptions={{this.mapOptions}} as |map|>
 *   <map.image @url="/icons/pin.png" @name="pin-icon" @onLoad={{this.onImageReady}} />
 * </MapLibreGL>
 * ```
 */
export default class MapLibreGLImage extends Component<MapLibreGLImageSignature> {
    /** @internal */
    _lastName?: string;
    private _lastLoadUrl?;
    private _lastLoadName?;
    private _lastLoadWidth?;
    private _lastLoadHeight?;
    private _lastLoadOptions?;
    /** @internal */
    get onError(): (err: unknown) => void;
    /** @internal */
    get onLoad(): () => void;
    /** @internal */
    get isSvg(): boolean;
    /** @internal */
    constructor(owner: Owner, args: MapLibreGLImageSignature['Args']);
    /** @internal */
    loadImage: (url: MapLibreGLImageSignature["Args"]["url"], name: MapLibreGLImageSignature["Args"]["name"], options?: MapLibreGLImageSignature["Args"]["options"], width?: MapLibreGLImageSignature["Args"]["width"], height?: MapLibreGLImageSignature["Args"]["height"]) => void;
    /** @internal */
    _onImage: (url: MapLibreGLImageSignature["Args"]["url"], name: MapLibreGLImageSignature["Args"]["name"], options?: MapLibreGLImageSignature["Args"]["options"], image?: Parameters<maplibregl.Map["addImage"]>[1]) => void;
    /** @internal */
    _onSvgErr: (_url: string, event: Event | string) => void;
}
//# sourceMappingURL=maplibre-gl-image.d.ts.map