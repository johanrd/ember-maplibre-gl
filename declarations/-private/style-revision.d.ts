import type { Map as MaplibreMap } from 'maplibre-gl';
/** Read before any early return, so the upsert runs again after `map.setStyle()`. */
export declare function consumeStyleRevision(map: MaplibreMap): number;
export declare function bumpStyleRevision(map: MaplibreMap): void;
/** False on a context-lost map, and while a style from `setStyle()` loads. As in react-map-gl. */
export declare function isStyleLoaded(map: MaplibreMap): boolean;
/** Called on an `error` while a style from `setStyle()` is unloaded: that style stays unloaded. */
export declare function markStyleFailed(map: MaplibreMap): void;
/** Lets settled() wait for the map's `setStyle()` calls. Returns the function that stops it. */
export declare function waitForStyleChanges(map: MaplibreMap): () => void;
//# sourceMappingURL=style-revision.d.ts.map