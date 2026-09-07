<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { inBrowser } from 'vitepress';

const mapContainer = ref<HTMLDivElement | null>(null);
const flying = ref(false);
let map: any = null;
let arcAnimationId: number | null = null;

// A round-the-world route, eastbound, one landmark per city
const cities = [
  [-73.994655, 40.694752], // Häagen-Dazs, 120 Montague St, Brooklyn
  [10.703554, 59.926021], // Sinnataggen, Vigelandsparken, Oslo
  [28.980011, 41.008505], // Hagia Sophia, Istanbul
  [55.274133, 25.197034], // Burj Khalifa, Dubai
  [77.229493, 28.612933], // India Gate, Delhi
  [103.854159, 1.285685], // Merlion Park, Singapore
  [151.215123, -33.857198], // Sydney Opera House
  [-157.866012, 21.30706], // Aloha Tower, Honolulu
  [-118.300293, 34.118219], // Griffith Observatory, Los Angeles
  [-73.994655, 40.694752], // back to the ice cream
];

// Longitudes run continuously past ±180 rather than wrapping, so the
// Sydney → Honolulu leg draws across the Pacific instead of streaking back
// around the globe. Every leg picks up where the last one ended, so the winding
// carries across the whole route.
function greatCircleArc(from: number[], to: number[], steps: number): number[][] {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const [lon1, lat1] = [toRad(from[0]), toRad(from[1])];
  const [lon2, lat2] = [toRad(to[0]), toRad(to[1])];
  const d = Math.acos(
    Math.sin(lat1) * Math.sin(lat2) + Math.cos(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1)
  );
  const unwrap = (lon: number, near: number) => lon + 360 * Math.round((near - lon) / 360);

  // Closer than ~640 m: sin(d) underflows. Hold still, but still return a full
  // leg so callers can index every vertex.
  if (d < 0.0001) {
    const end = [unwrap(to[0], from[0]), to[1]];
    return Array.from({ length: steps + 1 }, (_, i) => (i < steps ? [...from] : end));
  }

  const points: number[][] = [];
  let prevLon = from[0];
  for (let i = 0; i <= steps; i++) {
    const f = i / steps;
    const A = Math.sin((1 - f) * d) / Math.sin(d);
    const B = Math.sin(f * d) / Math.sin(d);
    const x = A * Math.cos(lat1) * Math.cos(lon1) + B * Math.cos(lat2) * Math.cos(lon2);
    const y = A * Math.cos(lat1) * Math.sin(lon1) + B * Math.cos(lat2) * Math.sin(lon2);
    const z = A * Math.sin(lat1) + B * Math.sin(lat2);
    const lon = unwrap(toDeg(Math.atan2(y, x)), prevLon);
    prevLon = lon;
    points.push([lon, toDeg(Math.atan2(z, Math.sqrt(x * x + y * y)))]);
  }
  return points;
}

const POINTS_PER_LEG = 100;

// Clock-driven rather than frame-counted, so the flight runs at one speed
// whether the display refreshes at 60 Hz or 120 Hz.
const LEG_MS = 830;
const PAUSE_MS = 500;

const legs: number[][][] = [];
for (let i = 1; i < cities.length; i++) {
  legs.push(greatCircleArc(legs.at(-1)?.at(-1) ?? cities[0], cities[i], POINTS_PER_LEG));
}

// The whole route as one line. It never changes, so the animation only ever
// moves the camera and repaints a gradient — no geometry goes to the worker.
const route = legs.reduce((all, leg) => all.concat(leg.slice(1)), [legs[0][0]]);

// line-progress measures distance in projected space, so the reveal has to be
// keyed off Mercator length or it drifts from the head at high latitudes.
function mercator([lon, lat]: number[]): number[] {
  return [(lon * Math.PI) / 180, Math.log(Math.tan(Math.PI / 4 + (lat * Math.PI) / 360))];
}
const routeLength: number[] = [0];
for (let i = 1; i < route.length; i++) {
  const [ax, ay] = mercator(route[i - 1]);
  const [bx, by] = mercator(route[i]);
  routeLength.push(routeLength[i - 1] + Math.hypot(bx - ax, by - ay));
}
const TOTAL_LENGTH = routeLength[routeLength.length - 1];

const TRAIL_SHARE = 1 / 3; // comet tail, as a share of the route
const TRAIL_ALPHA = 0.6;
const rgba = (a: number) => `rgba(224, 78, 57, ${a})`;

// Reveal the route only just behind the head, fading out along the tail.
function trailGradient(at: number) {
  const eps = 1e-4;
  const head = Math.min(Math.max(at, 2 * eps), 1 - 2 * eps);
  const tailStart = head - TRAIL_SHARE;
  if (tailStart > eps) {
    return ['interpolate', ['linear'], ['line-progress'],
      0, rgba(0),
      tailStart, rgba(0),
      head, rgba(TRAIL_ALPHA),
      head + eps, rgba(0),
      1, rgba(0)];
  }
  // The tail runs off the start of the line, so it picks up again at the far
  // end — same point on the globe, so the loop doesn't blink.
  const seam = rgba(TRAIL_ALPHA * (1 - head / TRAIL_SHARE));
  return ['interpolate', ['linear'], ['line-progress'],
    0, seam,
    head, rgba(TRAIL_ALPHA),
    head + eps, rgba(0),
    Math.min(1 - eps, 1 + tailStart), rgba(0),
    1, seam];
}

function easeInOut(t: number): number {
  return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
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
    map.addSource('cities', {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: cities.slice(0, -1).map((c) => ({
          type: 'Feature' as const,
          properties: {},
          geometry: { type: 'Point' as const, coordinates: c },
        })),
      },
    });
    map.addLayer({
      id: 'city-dots',
      type: 'circle',
      source: 'cities',
      paint: { 'circle-radius': 2, 'circle-color': '#E04E39', 'circle-opacity': 0.8 },
    });

    map.addSource('route', {
      type: 'geojson',
      lineMetrics: true, // required for ['line-progress']
      data: { type: 'Feature', properties: {}, geometry: { type: 'LineString', coordinates: route } },
    });
    map.addLayer({
      id: 'route-line',
      type: 'line',
      source: 'route',
      paint: { 'line-width': 1.5, 'line-gradient': trailGradient(0) },
    });

    let currentLeg = 0;
    let legStart = -1;
    let pauseUntil = 0;

    function animateTrail(now: number) {
      if (!map) return;
      arcAnimationId = requestAnimationFrame(animateTrail);

      if (now < pauseUntil) return;
      if (legStart < 0) legStart = now;

      const leg = legs[currentLeg];
      const progress = Math.min((now - legStart) / LEG_MS, 1);

      // Interpolate between arc vertices. Snapping to whole vertices pans the
      // camera 0, 1 or 2 steps per frame, which reads as jitter.
      const exact = easeInOut(progress) * POINTS_PER_LEG;
      const vertex = Math.min(Math.floor(exact), POINTS_PER_LEG - 1);
      const f = exact - vertex;
      const [aLon, aLat] = leg[vertex];
      const [bLon, bLat] = leg[vertex + 1];

      // The head is the map centre by construction, drawn as a fixed dot in the
      // template, so it can never drift out of step with the globe.
      map.setCenter([aLon + (bLon - aLon) * f, aLat + (bLat - aLat) * f]);

      const i = currentLeg * POINTS_PER_LEG + vertex;
      const along = routeLength[i] + (routeLength[i + 1] - routeLength[i]) * f;
      map.setPaintProperty('route-line', 'line-gradient', trailGradient(along / TOTAL_LENGTH), {
        validate: false,
      });

      if (progress >= 1) {
        currentLeg = (currentLeg + 1) % legs.length;
        legStart = -1;
        pauseUntil = now + PAUSE_MS;
      }
    }

    // Hand the globe over the moment the reader grabs it, and drop the head dot
    // with it — off the route, a dot pinned to the centre would be a lie.
    function stopAnimation() {
      if (arcAnimationId) cancelAnimationFrame(arcAnimationId);
      arcAnimationId = null;
      flying.value = false;
    }

    map.on('mousedown', stopAnimation);
    map.on('touchstart', stopAnimation);

    flying.value = true;
    arcAnimationId = requestAnimationFrame(animateTrail);
  });
});

onBeforeUnmount(() => {
  if (arcAnimationId) cancelAnimationFrame(arcAnimationId);
  map?.remove();
  map = null;
});
</script>

<template>
  <div class="hero-map" :class="{ flying }" ref="mapContainer" />
</template>

<style scoped>
.hero-map {
  position: relative;
  width: 320px;
  height: 320px;
  border-radius: 50%;
  overflow: hidden;
  margin: 0 auto;
}

.hero-map.flying::after {
  content: '';
  position: absolute;
  z-index: 2;
  top: 50%;
  left: 50%;
  width: 6px;
  height: 6px;
  margin: -3px 0 0 -3px;
  border-radius: 50%;
  background: #e04e39;
  pointer-events: none;
}

@media (max-width: 960px) {
  .hero-map {
    width: 240px;
    height: 240px;
  }
}
</style>
