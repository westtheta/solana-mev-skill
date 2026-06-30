# Jito Bundles

Jito bundle submission, tip optimization, searcher patterns, and bundle lifecycle management.

---

## Overview

Jito is the dominant MEV infrastructure on Solana. Searchers build **bundles** (atomic sequences of transactions) and submit them to Jito validators, who include the highest-bidding bundle in their block.

### How Jito Works

```
Searcher → Build Bundle → Submit to Jito Block Engine
                                        │
                        Validators compete for bundles
                                        │
                        Highest-tip bundle wins → included in block
```

## Bundle Structure

A Jito bundle is an ordered list of transactions that must all succeed or all fail (atomic).

```
Bundle
├── Tx 1: Setup (approve tokens, etc.)
├── Tx 2: Core MEV extraction (arb swap, liquidation)
├── Tx 3: Cleanup (repay loan, withdraw profit)
└── Tip Tx: Pay validator
```

### Bundle Rules

1. **Atomic** — all txs in the bundle execute or none do
2. **Ordered** — txs execute in the order they appear
3. **One-shot** — bundles are submitted for a specific slot
4. **Tip** — the bundle with the highest tip (per-CU) wins
5. **Unique tip account** — each bundle uses a unique tip account

## Bundle Building

### Basic Bundle

```typescript
import { Keypair, Transaction, VersionedTransaction } from '@solana/kit';
import { Bundle } from 'jito-sdk';

async function buildArbBundle(
  buyTx: VersionedTransaction,
  sellTx: VersionedTransaction,
  tipAmount: number, // in SOL
  tipAccount: Keypair,
): Promise<Bundle> {
  const bundle = new Bundle()
    .addTransactions([buyTx, sellTx])
    .setTip(tipAmount, tipAccount.publicKey);

  return bundle;
}
```

### Bundle with Tip Account Rotation

Jito requires each bundle to use a unique tip account to prevent frontrunning. Never reuse tip accounts.

```typescript
function generateTipAccount(): Keypair {
  return Keypair.generate(); // New keypair per bundle
}

function addTipToBundle(
  bundle: Bundle,
  amount: number, // in SOL
): Bundle {
  // The tip is a simple SOL transfer to Jito's tip account
  const tipIx = SystemProgram.transfer({
    fromPubkey: tipAccount.publicKey,
    toPubkey: JITO_TIP_ACCOUNT,
    lamports: amount * LAMPORTS_PER_SOL,
  });

  return bundle.addTipInstruction(tipIx);
}
```

## Bundle Submission

### Submit to Jito Block Engine

```typescript
import { JitoClient } from 'jito-sdk';

const jitoClient = new JitoClient({
  url: 'https://mainnet.block-engine.jito.wtf/api/v1',
  // or for devnet: 'https://devnet.block-engine.jito.wtf/api/v1'
});

async function submitBundle(bundle: Bundle): Promise<string> {
  const { uuid, result } = await jitoClient.submitBundle(bundle);

  if (result === 'Accepted') {
    console.log(`Bundle accepted: ${uuid}`);
    return uuid;
  } else {
    throw new Error(`Bundle rejected: ${result}`);
  }
}
```

### Bundle Status Polling

```typescript
async function pollBundleStatus(
  uuid: string,
  maxRetries = 10,
  intervalMs = 1000,
): Promise<'Landed' | 'Failed' | 'Dropped'> {
  for (let i = 0; i < maxRetries; i++) {
    const status = await jitoClient.getBundleStatus(uuid);

    if (status === 'Landed') return 'Landed';
    if (status === 'Failed') return 'Failed';

    await sleep(intervalMs);
  }

  return 'Dropped';
}
```

## Tip Optimization

Tip strategy is critical — over-tipping wastes profit, under-tipping loses the bundle.

### Tip Factors

| Factor | Impact |
|--------|--------|
| **Slot congestion** | More competition → higher tips needed |
| **Profit of opportunity** | Higher profit → can justify higher tip |
| **Time of day** | Higher activity periods → higher tips |
| **Bundle complexity** | More CUs → higher tip per CU |
| **Validator** | Some validators have higher minimum tips |

### Tip Strategies

#### Strategy 1: Historical Tip Tracking

```typescript
interface TipHistory {
  slot: number;
  winningTip: number; // in lamports per CU
}

const tipHistory: TipHistory[] = [];

async function getRecommendedTip(): Promise<number> {
  const recent = tipHistory.slice(-100);
  if (recent.length === 0) return 1000; // default: 0.001 SOL

  // Use 95th percentile of recent winning tips
  const sorted = recent.map(t => t.winningTip).sort((a, b) => a - b);
  const p95 = sorted[Math.floor(sorted.length * 0.95)];

  return p95 * 1.1; // 10% above 95th percentile
}
```

#### Strategy 2: Profit-Share

```typescript
function calculateTip(
  expectedProfit: number,
  confidence: number,
  competition: 'Low' | 'Medium' | 'High',
): number {
  const competitionMultiplier = {
    Low: 0.1,
    Medium: 0.2,
    High: 0.4,
  };

  // Tip = 10-40% of expected profit based on competition
  return expectedProfit * competitionMultiplier[competition] * confidence;
}
```

#### Strategy 3: Auction Simulation

```typescript
async function simulateAuction(
  bundle: Bundle,
  tipRange: [number, number],
  steps: number,
): Promise<number> {
  const results = [];

  for (let i = 0; i < steps; i++) {
    const tip = tipRange[0] + (tipRange[1] - tipRange[0]) * (i / steps);
    bundle.setTip(tip);

    const { accepted } = await jitoClient.simulateBundle(bundle);
    results.push({ tip, accepted });
  }

  // Return the lowest accepted tip
  const accepted = results.filter(r => r.accepted);
  return accepted.length > 0 ? accepted[0].tip : tipRange[1];
}
```

## Searcher Patterns

### Pattern 1: Mempool Searcher

Monitor the Jito mempool for profitable transactions to backrun.

```typescript
const mempoolStream = jitoClient.subscribeMempool();

mempoolStream.on('tx', async (tx: Transaction) => {
  const opportunity = await analyzeTx(tx);

  if (opportunity.profitable) {
    const bundle = await buildBackrunBundle(tx, opportunity);
    await submitBundle(bundle);
  }
});
```

### Pattern 2: Scheduled Searcher

Run MEV strategies on a schedule (every slot, every N slots).

```typescript
async function searcherLoop() {
  while (true) {
    const slot = await connection.getSlot();

    // Check arb opportunities
    const arbOps = await scanDexes();
    for (const op of arbOps) {
      const bundle = await buildArbBundle(op);
      await submitBundle(bundle);
    }

    // Wait for next slot
    await sleep(400); // ~400ms per slot
  }
}
```

### Pattern 3: Event-Driven Searcher

React to specific on-chain events (new pools, large swaps, liquidations).

```typescript
const geyserStream = await createGeyserStream();

geyserStream.on('accountUpdate', async (update: AccountUpdate) => {
  if (isLiquidationEvent(update)) {
    const bundle = await buildLiquidationBundle(update);
    await submitBundle(bundle);
  }
});
```

## Error Handling

### Common Bundle Failures

| Error | Cause | Fix |
|-------|-------|-----|
| `BlockhashNotFound` | Blockhash expired | Retry with fresh blockhash |
| `BundleNotAccepted` | Tip too low or invalid txs | Increase tip, verify txs |
| `TransactionFailure` | One of the bundle txs failed | Simulate bundle locally first |
| `TipAccountAlreadyUsed` | Tip account reused | Generate new tip account |
| `SimulationFailure` | Bundle would fail on-chain | Debug individual txs |

### Retry Logic

```typescript
async function submitWithRetry(
  bundle: Bundle,
  maxRetries = 5,
): Promise<string> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const uuid = await submitBundle(bundle);
      return uuid;
    } catch (error) {
      if (i === maxRetries - 1) throw error;

      // Refresh blockhash and tip account
      bundle.refreshBlockhash();
      bundle.refreshTipAccount();

      await sleep(500 * (i + 1)); // Exponential backoff
    }
  }

  throw new Error('Max retries exceeded');
}
```

## Bundle Simulation

Always simulate bundles locally before submission.

```typescript
async function simulateBundle(
  bundle: Bundle,
  rpcUrl: string,
): Promise<SimulationResult> {
  const simulation = await connection.simulateBundle(bundle);

  return {
    willSucceed: simulation.err === null,
    cuUsed: simulation.unitsConsumed,
    logs: simulation.logs,
  };
}
```

## Bundle vs Individual Transaction

| Aspect | Bundle | Individual Tx |
|--------|--------|---------------|
| Atomicity | ✅ All or nothing | ❌ Can partially fail |
| MEV protection | ✅ No frontrunning | ❌ Visible in mempool |
| Complexity | Multiple txs | Single tx |
| Cost | Tip + fees | Fees only |
| Slot targeting | Specific slot | Next slot |

## Jito Block Engine API

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/bundles` | POST | Submit bundle |
| `/api/v1/bundles/{uuid}` | GET | Check bundle status |
| `/api/v1/mempool` | WebSocket | Subscribe to mempool |
| `/api/v1/tip` | GET | Get current tip floor |

---

**Related skills:**
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
- [arbitrage.md](arbitrage.md) — Building arb bundles
- [liquidations.md](liquidations.md) — Building liquidation bundles
- [mempool-monitoring.md](mempool-monitoring.md) — Yellowstone gRPC streaming
