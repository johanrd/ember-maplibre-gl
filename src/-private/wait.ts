import { macroCondition, isDevelopingApp } from '@embroider/macros';
import type { buildWaiter } from '@ember/test-waiters';

type Waiter = ReturnType<typeof buildWaiter>;

// Upper bound for work that never finishes, fails, or gets torn down (e.g. a
// request that never answers). Without it, settled() hangs until the test
// itself times out, and every later test inherits the pending waiter.
const WAIT_TIMEOUT_MS = 10_000;

const noop = () => {};

/**
 * Holds settled() open until the returned function is called, or until the
 * timeout passes — which warns, because settled() then carries on as if the
 * work had finished. Calling the returned function more than once is safe.
 *
 * Development builds only (which includes test builds): settled() does not
 * exist in production, so there is nothing to hold open and no timer to run.
 */
export function beginWait(waiter: Waiter, label: string): () => void {
  if (macroCondition(!isDevelopingApp())) {
    return noop;
  }

  let waiting = true;
  const token = waiter.beginAsync(undefined, label);
  const timeout = setTimeout(() => {
    console.warn(
      `ember-maplibre-gl: ${label} did not finish within ${WAIT_TIMEOUT_MS}ms, ` +
        `so anything waiting on it carries on without it.`,
    );
    endWait();
  }, WAIT_TIMEOUT_MS);

  function endWait() {
    if (!waiting) return;
    waiting = false;
    clearTimeout(timeout);
    waiter.endAsync(token);
  }

  return endWait;
}
