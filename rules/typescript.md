---
globs:
  - "app/**/*.{ts,tsx}"
  - "src/**/*.{ts,tsx}"
  - "tests/**/*.ts"
exclude:
  - "**/node_modules/**"
  - "**/dist/**"
  - "**/*.d.ts"
---

# TypeScript Standards for MEV Bots

These rules apply to searcher and bot TypeScript code.

## Type Safety

### NO any types

```typescript
// BAD
function process(data: any) {
  return data.value;
}

// GOOD
interface BundleResult {
  uuid: string;
  status: 'Accepted' | 'Rejected';
}

function process(data: BundleResult): string {
  return data.uuid;
}
```

### Explicit return types for functions

```typescript
// BAD
async function simulateBundle(bundle) {
  return bundle.simulate();
}

// GOOD
async function simulateBundle(bundle: Bundle): Promise<SimulationResult> {
  return bundle.simulate();
}
```

## Solana-Specific Patterns

### Use @solana/kit (not web3.js for new code)

```typescript
// BAD
import { Connection, PublicKey } from '@solana/web3.js';

// GOOD
import { Connection, PublicKey } from '@solana/kit';
```

### Handle RPC errors gracefully

```typescript
async function safeRpcCall<T>(
  fn: () => Promise<T>,
  retries = 3,
): Promise<T> {
  for (let i = 0; i < retries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === retries - 1) throw error;
      await sleep(1000 * (i + 1));
    }
  }
  throw new Error('Max retries exceeded');
}
```

### Bundle types

```typescript
interface BundleSubmission {
  uuid: string;
  transactions: string[]; // base64-encoded
  tip: number; // in lamports
  tipAccount: string;
}

interface BundleStatus {
  uuid: string;
  status: 'Pending' | 'Landed' | 'Failed';
  slot?: number;
}
```

## Performance

### Avoid blocking operations

```typescript
// BAD — synchronous sleep
function wait(ms: number) {
  const start = Date.now();
  while (Date.now() - start < ms);
}

// GOOD — async sleep
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Use Promise.all for parallel RPC calls

```typescript
// BAD — sequential
const price1 = await getOrcaPrice(token);
const price2 = await getRaydiumPrice(token);

// GOOD — parallel
const [price1, price2] = await Promise.all([
  getOrcaPrice(token),
  getRaydiumPrice(token),
]);
```

## Error Handling

### Never swallow errors silently

```typescript
// BAD
try {
  await submitBundle(bundle);
} catch {
  // silent
}

// GOOD
try {
  await submitBundle(bundle);
} catch (error) {
  console.error(`Bundle submission failed: ${error}`);
  // Handle appropriately
  throw error;
}
```
