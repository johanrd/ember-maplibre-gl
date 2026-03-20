<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { inBrowser } from 'vitepress';

const mapContainer = ref<HTMLDivElement | null>(null);
let map: any = null;
let animationId: number | null = null;

onMounted(async () => {
  if (!inBrowser || !mapContainer.value) return;

  const { Map } = await import('maplibre-gl');
  map = new Map({
    container: mapContainer.value,
    style: 'https://demotiles.maplibre.org/globe.json',
    center: [0, 20],
    zoom: 1,
    projection: 'globe',
    attributionControl: false,
    pitchWithRotate: false,
    dragRotate: false,
    touchPitch: false,
    maxPitch: 0,
  });

  function rotate() {
    if (!map) return;
    const center = map.getCenter();
    center.lng += 0.02;
    map.setCenter(center);
    animationId = requestAnimationFrame(rotate);
  }

  map.on('load', rotate);

  map.on('mousedown', () => {
    if (animationId) cancelAnimationFrame(animationId);
    animationId = null;
  });
  map.on('mouseup', rotate);
  map.on('touchstart', () => {
    if (animationId) cancelAnimationFrame(animationId);
    animationId = null;
  });
  map.on('touchend', rotate);
});

onBeforeUnmount(() => {
  if (animationId) cancelAnimationFrame(animationId);
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
