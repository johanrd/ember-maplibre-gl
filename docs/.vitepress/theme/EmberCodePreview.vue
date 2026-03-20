<script lang="ts">
import { EMBER_OWNER_KEY } from 'vite-plugin-ember/setup';
export { EMBER_OWNER_KEY };
</script>

<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, inject } from 'vue';
import { inBrowser } from 'vitepress';
import { createOwner } from 'vite-plugin-ember/setup';

const props = defineProps<{
  src?: string;
  loader?: () => Promise<any>;
  owner?: object;
  preview?: boolean;
  collapsible?: boolean;
}>();
const injectedOwner = inject<object | undefined>(EMBER_OWNER_KEY, undefined);
const mountEl = ref<HTMLDivElement | null>(null);
const error = ref<string | null>(null);
let cleanup: undefined | { destroy?: () => void };

let rendererPromise: Promise<{ renderComponent: Function }> | undefined;

function getRenderer() {
  rendererPromise ??= import('@ember/renderer') as any;
  return rendererPromise!;
}

onMounted(async () => {
  if (!inBrowser || !mountEl.value) return;

  try {
    const [mod, { renderComponent }] = await Promise.all([
      props.loader ? props.loader() : import(/* @vite-ignore */ props.src!),
      getRenderer(),
    ]);

    const component = mod?.default ?? mod;

    // Create a fresh owner per render. The Glimmer template compiler caches
    // compiled templates in a WeakMap keyed by owner. If we reuse the same
    // owner across SPA navigations, the cache returns stale compiled handles
    // that reference the previous (destroyed) renderer's program heap,
    // causing "syscall is null" errors.
    const baseOwner = props.owner ?? injectedOwner;
    const freshOwner = createOwner();
    // Copy any registered services from the shared owner
    if (baseOwner && 'lookup' in baseOwner) {
      (freshOwner as any)._parent = baseOwner;
      const origLookup = freshOwner.lookup.bind(freshOwner);
      freshOwner.lookup = (fullName: string) => {
        return origLookup(fullName) ?? (baseOwner as any).lookup?.(fullName);
      };
    }

    cleanup = renderComponent(component, {
      into: mountEl.value,
      owner: freshOwner,
    });
  } catch (err) {
    console.error('[CodePreview] Failed to render:', err);
    error.value = String(err);
  }
});

onBeforeUnmount(() => {
  cleanup?.destroy?.();
  cleanup = undefined;
});
</script>

<template>
  <div class="ember-playground">
    <div v-if="error" class="ember-playground__error">{{ error }}</div>
    <div ref="mountEl"></div>
    <details
      v-if="$slots.default && collapsible"
      class="ember-playground__source"
    >
      <summary>Show code</summary>
      <slot />
    </details>
    <div v-else-if="$slots.default" class="ember-playground__source">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.ember-playground {
  padding: 12px;
  border: 1px solid var(--vp-c-divider);
  border-radius: 10px;
}

.ember-playground__error {
  padding: 8px 12px;
  margin-bottom: 8px;
  border-radius: 6px;
  background: var(--vp-c-danger-soft);
  color: var(--vp-c-danger-1);
  font-size: 13px;
  font-family: var(--vp-font-family-mono);
  white-space: pre-wrap;
  word-break: break-word;
}

.ember-playground__source {
  margin-top: 12px;
  border-top: 1px solid var(--vp-c-divider);
}

.ember-playground__source summary {
  padding: 8px 0 4px;
  cursor: pointer;
  font-size: 13px;
  color: var(--vp-c-text-2);
  user-select: none;
}

.ember-playground__source summary:hover {
  color: var(--vp-c-text-1);
}

.ember-playground__source :deep(div[class*='language-']) {
  margin: 0;
  border-radius: 0 0 8px 8px;
}
</style>
