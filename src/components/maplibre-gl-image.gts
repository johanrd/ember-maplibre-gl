import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type MapLibreGL from './maplibre-gl.gts';
import {
  associateDestroyableChild,
  isDestroyed,
  isDestroying,
  registerDestructor,
} from '@ember/destroyable';
import type maplibregl from 'maplibre-gl';
import type Owner from '@ember/owner';

export interface MapLibreGLImageArgs {
  map: maplibregl.Map;
  url?: Parameters<maplibregl.Map['loadImage']>['0'];
  name: Parameters<maplibregl.Map['addImage']>['0'];
  options?: Parameters<maplibregl.Map['addImage']>['2'];
  width?: HTMLImageElement['width'];
  height?: HTMLImageElement['height'];
  onLoad?: () => void;
  onError?: (err: unknown) => void;
  parent?: MapLibreGL;
}

export interface MapLibreGLImageSignature {
  Args: MapLibreGLImageArgs;
}

function noop() {}

export class SvgLoadError extends Error {
  event: Event | string;

  constructor(message: string, event: Event | string) {
    super(message);
    this.event = event;
  }
}

export default class MapLibreGLImage extends Component<MapLibreGLImageSignature> {
  @tracked _lastName?: string;

  get onError() {
    return this.args.onError || noop;
  }
  get onLoad() {
    return this.args.onLoad || noop;
  }

  get isSvg(): boolean {
    const url = this.args.url;
    if (!url || typeof url !== 'string') {
      return false;
    }
    return /\.svg$/.test(url);
  }

  constructor(owner: Owner, args: MapLibreGLImageArgs) {
    super(owner, args);
    this.loadImage(args.url, args.name, args.options, args.width, args.height);

    if (args.parent) associateDestroyableChild(args.parent, this);
    registerDestructor(this, () => {
      try {
        if (this.args.name && this.args.map?.hasImage(this.args.name)) {
          this.args.map.removeImage(this.args.name);
        }
      } catch {
        // Map may be in a broken state (e.g. WebGL context lost)
      }
    });
  }

  loadImage = (
    url: MapLibreGLImageArgs['url'],
    name: MapLibreGLImageArgs['name'],
    options?: MapLibreGLImageArgs['options'],
    width?: MapLibreGLImageArgs['width'],
    height?: MapLibreGLImageArgs['height'],
  ) => {
    // If the component already has added an image to the map, remove it
    if (this._lastName && this.args.map.hasImage(this._lastName)) {
      this.args.map.removeImage(this._lastName);
    }

    if (!url) {
      return;
    }

    if (this.isSvg) {
      const image = new Image();
      if (width) {
        image.width = width;
      }

      if (height) {
        image.height = height;
      }

      image.onload = () => this._onImage(url, name, options, image);
      image.onerror = (event) => this._onSvgErr(url, event);
      image.src = url;
    } else {
      this.args.map
        .loadImage(url)
        .then(({ data }) => this._onImage(url, name, options, data))
        .catch((error) => this.onError(error));
    }
  };

  _onImage = (
    url: MapLibreGLImageArgs['url'],
    name: MapLibreGLImageArgs['name'],
    options?: MapLibreGLImageArgs['options'],
    image?: Parameters<maplibregl.Map['addImage']>[1],
  ) => {
    if (isDestroying(this) || isDestroyed(this)) {
      return;
    }

    if (this.args.url !== url) {
      // image has changed since we started loading
      return;
    }

    this.args.map.addImage(name, image!, options);

    this._lastName = name;

    this.onLoad();
  };

  _onSvgErr = (_url: string, event: Event | string) => {
    this.onError(new SvgLoadError('Failed to load svg', event));
  };

  <template>{{this.loadImage @url @name @options @width @height}}</template>
}
