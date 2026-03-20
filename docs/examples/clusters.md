# Clusters

Visualize dense point data with dynamic clustering. Cluster circles are color-coded and sized by count. Click a cluster to zoom in.

```gts live preview
import type { MapMouseEvent } from 'maplibre-gl';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  center: [-103.59, 40.66] as [number, number],
  zoom: 3,
};

const source = {
  type: 'geojson' as const,
  data: 'https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson',
  cluster: true,
  clusterMaxZoom: 14,
  clusterRadius: 50,
};

const clusterLayer = {
  id: 'clusters',
  type: 'circle' as const,
  filter: ['has', 'point_count'],
  paint: {
    'circle-color': [
      'step', ['get', 'point_count'],
      '#51bbd6', 100,
      '#f1f075', 750,
      '#f28cb1',
    ],
    'circle-radius': [
      'step', ['get', 'point_count'],
      20, 100,
      30, 750,
      40,
    ],
  },
};

const clusterCountLayer = {
  type: 'symbol' as const,
  filter: ['has', 'point_count'],
  layout: {
    'text-field': '{point_count_abbreviated}',
    'text-size': 12,
  },
};

const pointLayer = {
  id: 'unclustered-point',
  type: 'circle' as const,
  filter: ['!', ['has', 'point_count']],
  paint: {
    'circle-color': '#11b4da',
    'circle-radius': 5,
    'circle-stroke-width': 1.5,
    'circle-stroke-color': '#fff',
  },
};

const onClusterClick = (e: MapMouseEvent) => {
  const map = e.target;
  const features = map.queryRenderedFeatures(e.point, {
    layers: ['clusters'],
  });
  if (!features.length) return;
  const clusterId = features[0].properties.cluster_id;
  (map.getSource(features[0].source) as any).getClusterExpansionZoom(clusterId)
    .then((zoom: number) => {
      map.easeTo({ center: (features[0].geometry as any).coordinates, zoom });
    });
};

<template>
  <MapLibreGL
    @initOptions={{mapOptions}}
    style="height: 500px; width: 100%; border-radius: 8px; cursor: pointer;"
  as |map|>
    <map.source @options={{source}} as |source|>
      <source.layer @options={{clusterLayer}} />
      <source.layer @options={{clusterCountLayer}} />
      <source.layer @options={{pointLayer}} />
    </map.source>
    <map.on @event="click" @layerId="clusters" @action={{onClusterClick}} />
  </MapLibreGL>
</template>
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/create-and-style-clusters/">Cluster</a> example.</p>
