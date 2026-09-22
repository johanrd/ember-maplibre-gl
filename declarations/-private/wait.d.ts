import type { buildWaiter } from '@ember/test-waiters';
type Waiter = ReturnType<typeof buildWaiter>;
/**
 * Holds settled() open until the returned function is called, or until the
 * timeout passes — which warns, because settled() then carries on as if the
 * work had finished. Calling the returned function more than once is safe.
 *
 * Development builds only (which includes test builds): settled() does not
 * exist in production, so there is nothing to hold open and no timer to run.
 */
export declare function beginWait(waiter: Waiter, label: string): () => void;
export {};
//# sourceMappingURL=wait.d.ts.map