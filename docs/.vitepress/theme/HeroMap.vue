<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { inBrowser } from 'vitepress';

const mapContainer = ref<HTMLDivElement | null>(null);
let map: any = null;
let arcAnimationId: number | null = null;

// A round-the-world route, city to city
// Goes via southern Pacific (Sydney → Auckland → Honolulu) to avoid antimeridian artifacts
const cities = [
  [-73.94, 40.67],   // New York
  [10, 60],          // Oslo
  [28.97, 41.01],    // Istanbul
  [55.27, 25.2],     // Dubai
  [77.21, 28.61],    // Delhi
  [103.82, 1.35],    // Singapore
  [151.21, -33.87],  // Sydney
  [-157.86, 21.31],  // Honolulu
  [-118.24, 34.05],  // Los Angeles
  [-73.94, 40.67],   // back to New York
];

function greatCircleArc(from: number[], to: number[], steps = 100): number[][] {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const [lon1, lat1] = [toRad(from[0]), toRad(from[1])];
  const [lon2, lat2] = [toRad(to[0]), toRad(to[1])];
  const d = Math.acos(
    Math.sin(lat1) * Math.sin(lat2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1)
  );
  if (d < 0.0001) return [from, to];
  const points: number[][] = [];
  for (let i = 0; i <= steps; i++) {
    const f = i / steps;
    const A = Math.sin((1 - f) * d) / Math.sin(d);
    const B = Math.sin(f * d) / Math.sin(d);
    const x = A * Math.cos(lat1) * Math.cos(lon1) + B * Math.cos(lat2) * Math.cos(lon2);
    const y = A * Math.cos(lat1) * Math.sin(lon1) + B * Math.cos(lat2) * Math.sin(lon2);
    const z = A * Math.sin(lat1) + B * Math.sin(lat2);
    points.push([toDeg(Math.atan2(y, x)), toDeg(Math.atan2(z, Math.sqrt(x * x + y * y)))]);
  }
  return points;
}

const POINTS_PER_LEG = 100;
const legs = cities.slice(0, -1).map((city, i) => greatCircleArc(city, cities[i + 1], POINTS_PER_LEG));
const PAUSE_FRAMES = 60;

// Ease-in-out: slow start, fast middle, slow arrival
function easeInOut(t: number): number {
  return t < 0.5
    ? 2 * t * t
    : 1 - Math.pow(-2 * t + 2, 2) / 2;
}

onMounted(async () => {
  if (!inBrowser || !mapContainer.value) return;

  const { Map } = await import('maplibre-gl');
  map = new Map({
    container: mapContainer.value,
    style: 'https://demotiles.maplibre.org/globe.json',
    center: cities[0],
    zoom: window.innerWidth <= 960 ? 0.65 : 1,
    projection: 'globe',
    attributionControl: false,
    pitchWithRotate: false,
    dragRotate: false,
    touchPitch: false,
    maxPitch: 0,
  });

  map.on('load', () => {
    // City dots
    const cityFeatures = cities.slice(0, -1).map((c) => ({
      type: 'Feature' as const,
      properties: {},
      geometry: { type: 'Point' as const, coordinates: c },
    }));
    map.addSource('cities', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: cityFeatures },
    });
    map.addLayer({
      id: 'city-dots',
      type: 'circle',
      source: 'cities',
      paint: { 'circle-radius': 2, 'circle-color': '#E04E39', 'circle-opacity': 0.8 },
    });

    // Trail line
    map.addSource('trail', {
      type: 'geojson',
      data: { type: 'Feature', properties: {}, geometry: { type: 'LineString', coordinates: [] } },
    });
    map.addLayer({
      id: 'trail-line',
      type: 'line',
      source: 'trail',
      paint: {
        'line-color': '#E04E39',
        'line-width': 1.5,
        'line-opacity': 0.6,
      },
    });

    // Head dot
    map.addSource('head', {
      type: 'geojson',
      data: { type: 'Feature', properties: {}, geometry: { type: 'Point', coordinates: cities[0] } },
    });
    map.addLayer({
      id: 'head-dot',
      type: 'circle',
      source: 'head',
      paint: { 'circle-radius': 3, 'circle-color': '#E04E39', 'circle-opacity': 1 },
    });

    let currentLeg = 0;
    let legFrame = 0;
    let pauseCounter = 0;
    let trail: number[][] = [cities[0]];
    let lastPointIndex = 0;
    const MAX_TRAIL_POINTS = POINTS_PER_LEG * 3; // keep only ~3 legs of trail

    function animateTrail() {
      if (!map) return;

      if (pauseCounter > 0) {
        pauseCounter--;
        arcAnimationId = requestAnimationFrame(animateTrail);
        return;
      }

      const leg = legs[currentLeg];
      legFrame++;

      // Map legFrame to eased position in the arc
      const linearProgress = Math.min(legFrame / POINTS_PER_LEG, 1);
      const easedProgress = easeInOut(linearProgress);
      const targetIndex = Math.min(Math.floor(easedProgress * POINTS_PER_LEG), POINTS_PER_LEG);

      // Add all points between lastPointIndex and targetIndex
      for (let i = lastPointIndex + 1; i <= targetIndex; i++) {
        trail.push(leg[i]);
      }
      lastPointIndex = targetIndex;

      // Trim trail to last ~3 legs
      if (trail.length > MAX_TRAIL_POINTS) {
        trail = trail.slice(trail.length - MAX_TRAIL_POINTS);
      }

      if (linearProgress >= 1) {
        // Arrived at next city
        currentLeg++;
        legFrame = 0;
        lastPointIndex = 0;
        pauseCounter = PAUSE_FRAMES;

        if (currentLeg >= legs.length) {
          // Loop — don't clear the trail, just reset the leg counter.
          // The MAX_TRAIL_POINTS trim handles fading the old tail naturally.
          currentLeg = 0;
        }

        arcAnimationId = requestAnimationFrame(animateTrail);
        return;
      }

      const pos = leg[targetIndex];

      map.getSource('trail')?.setData({
        type: 'Feature',
        properties: {},
        geometry: { type: 'LineString', coordinates: trail },
      });

      map.getSource('head')?.setData({
        type: 'Feature',
        properties: {},
        geometry: { type: 'Point', coordinates: pos },
      });

      map.setCenter(pos);

      arcAnimationId = requestAnimationFrame(animateTrail);
    }

    animateTrail();
  });

  map.on('mousedown', () => {
    if (arcAnimationId) cancelAnimationFrame(arcAnimationId);
    arcAnimationId = null;
  });
  map.on('touchstart', () => {
    if (arcAnimationId) cancelAnimationFrame(arcAnimationId);
    arcAnimationId = null;
  });
});

onBeforeUnmount(() => {
  if (arcAnimationId) cancelAnimationFrame(arcAnimationId);
  map?.remove();
  map = null;
});
</script>

<template>
  <div class="hero-map" ref="mapContainer" />
</template>

<style scoped>
.hero-map {
  width: 320px;
  height: 320px;
  border-radius: 50%;
  overflow: hidden;
  margin: 0 auto;
}

@media (max-width: 960px) {
  .hero-map {
    width: 240px;
    height: 240px;
  }
}
</style>
