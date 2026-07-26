# Copilot review disagreements

## 1. PR #45 — cap maplibre-gl peer range at `<7`
Copilot suggested constraining `peerDependencies.maplibre-gl` from `>=5.0.0` to `>=5.0.0 <7`.
Rejected: the open-ended range is deliberate. The maintainer wants consumers to be able to
adopt future MapLibre majors without peer-warning churn. The addon sticks to public MapLibre
APIs, and the one internals-based feature (map reuse) runtime-guards `_container` and falls
back to fresh map creation, so an incompatible future major degrades gracefully instead of
breaking installs.

## 2. PR #45 — guard reuse path against custom @mapLib maps missing public methods
Copilot warned that the reuse guard only checks `_container` while the reuse path calls
`isStyleLoaded()` / `triggerRepaint()`, which a custom `@mapLib` map might lack.
Rejected: not a regression — the reuse path has always called unguarded public methods
(`resize`, `jumpTo`, `fire`, `isStyleLoaded`) on pooled maps. The guard exists for private
internals that can vanish silently between MapLibre versions; the public Map API is the
documented contract of `@mapLib`, and Mapbox GL v1 (the supported swap) implements both
methods.
