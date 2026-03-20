# 3D Tiles with Three.js

Load [OGC 3D Tiles](https://www.ogc.org/standard/3dtiles/) into a MapLibre map using [Three.js](https://threejs.org/) and [3d-tiles-renderer](https://github.com/NASA-AMMOS/3DTilesRendererJS). This example uses the `@mapLoaded` callback to add a custom Three.js rendering layer.

```gts live preview
import Component from '@glimmer/component';
import * as THREE from 'three';
import { TilesRenderer } from '3d-tiles-renderer';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';
import MapLibreGL from 'ember-maplibre-gl/components/maplibre-gl';
import maplibregl from 'maplibre-gl';

const mapOptions = {
  style: 'https://tiles.openfreemap.org/styles/bright',
  zoom: 1,
  center: [0, 0],
  pitch: 60,
  maxPitch: 80,
  canvasContextAttributes: { antialias: true },
};

function ecefToLngLatAlt(x, y, z) {
  const a = 6378137.0;
  const e2 = 6.69437999014e-3;
  const b = a * Math.sqrt(1 - e2);
  const ep2 = (a * a - b * b) / (b * b);
  const p = Math.sqrt(x * x + y * y);
  const th = Math.atan2(a * z, b * p);
  const lon = Math.atan2(y, x);
  const lat = Math.atan2(
    z + ep2 * b * Math.pow(Math.sin(th), 3),
    p - e2 * a * Math.pow(Math.cos(th), 3),
  );
  const n = a / Math.sqrt(1 - e2 * Math.sin(lat) * Math.sin(lat));
  const alt = p / Math.cos(lat) - n;
  return { lng: (lon * 180) / Math.PI, lat: (lat * 180) / Math.PI, alt };
}

export default class ThreeJSTilesDemo extends Component {
  onMapLoaded = (map) => {
    let scene, camera, renderer, tiles, tilesCamera, localTransform;

    function getModelTransform(coord) {
      const mc = maplibregl.MercatorCoordinate.fromLngLat(
        [coord[0], coord[1]], coord[2],
      );
      return {
        translateX: mc.x, translateY: mc.y, translateZ: mc.z,
        rotateX: Math.PI / 2, rotateY: 0, rotateZ: 0,
        scale: mc.meterInMercatorCoordinateUnits(),
      };
    }

    function updateLocalTransform(origin = [0, 0, 0]) {
      const t = getModelTransform(origin);
      const rx = new THREE.Matrix4().makeRotationX(t.rotateX);
      const ry = new THREE.Matrix4().makeRotationY(t.rotateY);
      const rz = new THREE.Matrix4().makeRotationZ(t.rotateZ);
      localTransform = new THREE.Matrix4()
        .makeTranslation(t.translateX, t.translateY, t.translateZ)
        .scale(new THREE.Vector3(t.scale, -t.scale, t.scale))
        .multiply(rx).multiply(ry).multiply(rz);
    }

    const customLayer = {
      id: '3d-tiles',
      type: 'custom',
      renderingMode: '3d',
      onAdd(mapArg, gl) {
        camera = new THREE.PerspectiveCamera();
        scene = new THREE.Scene();
        scene.add(new THREE.AmbientLight(0xffffff, 3));

        renderer = new THREE.WebGLRenderer({
          canvas: mapArg.getCanvas(), context: gl, antialias: true,
        });
        renderer.autoClear = false;
        tilesCamera = new THREE.PerspectiveCamera();

        const gltfLoader = new GLTFLoader();
        const dracoLoader = new DRACOLoader();
        dracoLoader.setDecoderPath('https://unpkg.com/three@0.183.0/examples/jsm/libs/draco/');
        gltfLoader.setDRACOLoader(dracoLoader);

        tiles = new TilesRenderer(
          'https://pelican-public.s3.amazonaws.com/3dtiles/agi-hq/tileset.json',
        );
        tiles.group.name = 'tiles';
        scene.add(tiles.group);
        tiles.setCamera(tilesCamera);
        tiles.setResolutionFromRenderer(tilesCamera, renderer);
        tiles.manager.addHandler(/\.(gltf|glb)$/g, gltfLoader);

        let handled = false;
        tiles.addEventListener('load-tileset', () => {
          if (handled) return;
          handled = true;

          const sphere = new THREE.Sphere();
          tiles.getBoundingSphere(sphere);
          const c = sphere.center.clone();
          const { lng, lat, alt } = ecefToLngLatAlt(c.x, c.y, c.z);
          map.jumpTo({ center: [lng, lat], zoom: 18, pitch: 60 });
          updateLocalTransform([lng, lat, alt - 300]);

          const m = tiles.root.transform || [1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
          const rot = new THREE.Matrix3().set(m[0],m[1],m[2],m[8],m[9],m[10],-m[4],-m[5],-m[6]);
          const move = new THREE.Matrix4().makeTranslation(-c.x, -c.y, -c.z);
          tiles.group.matrix.copy(
            new THREE.Matrix4().setFromMatrix3(rot).multiply(move),
          );
          tiles.group.matrixAutoUpdate = false;
          tiles.group.updateMatrixWorld(true);
        });

        updateLocalTransform();
      },
      render(_gl, args) {
        if (!camera || !renderer || !scene || !localTransform) return;
        camera.projectionMatrix.fromArray(args.defaultProjectionData.mainMatrix);
        camera.projectionMatrix.multiply(localTransform);

        const P = new THREE.Matrix4().fromArray(args.projectionMatrix);
        const V = new THREE.Matrix4().multiplyMatrices(P.clone().invert(), camera.projectionMatrix);
        tilesCamera.projectionMatrix.copy(P);
        tilesCamera.matrixWorldInverse.copy(V);
        tilesCamera.matrixWorld.copy(V).invert();

        renderer.resetState();
        renderer.render(scene, camera);
        if (tiles) tiles.update();
        map.triggerRepaint();
      },
    };

    map.addLayer(customLayer);
  };

  <template>
    <MapLibreGL
      @initOptions={{mapOptions}}
      @mapLoaded={{this.onMapLoaded}}
      style="height: 500px; width: 100%; border-radius: 8px;"
    />
  </template>
}
```
<p style="text-align: center; font-size: 12px; color: var(--vp-c-text-3); margin-top: 8px;">Based on the MapLibre GL JS <a href="https://maplibre.org/maplibre-gl-js/docs/examples/add-3d-tiles-using-threejs/">Add 3D tiles using Three.js</a> example.</p>
