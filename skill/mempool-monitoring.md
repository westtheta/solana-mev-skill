# Mempool Monitoring

Real-time monitoring infrastructure for Solana MEV: Yellowstone gRPC, Jito mempool, slot streaming, and transaction lifecycle tracking.

---

## Monitoring Infrastructure Overview

| Service | Data Source | Use Case |
|---------|-------------|----------|
| **Yellowstone gRPC** | Geyser plugin | Real-time account/slot/tx streaming |
| **Jito Mempool** | Jito Block Engine | Pending transaction visibility |
| **WebSocket RPC** | Standard RPC | Account subscription, logs |
| **Polling** | JSON-RPC | Slot health, missed slots |

## Yellowstone gRPC

The primary infrastructure for real-time Solana data streaming.

### Setup

```typescript
import { Client } from 'yellowstone-grpc';

const client = new Client({
  url: GRPC_ENDPOINT, // e.g., from Helius or Triton
  // authentication if needed
  token: GRPC_TOKEN,
});
```

### Account Streaming

Stream specific accounts for real-time health factor monitoring.

```typescript
interface AccountStreamConfig {
  accounts: {
    account: string; // base58 account address
    filters?: {
      dataSize?: number;
      memcmp?: {
        offset: number;
        bytes: string;
      };
    };
  }[];
  onUpdate: (update: AccountUpdate) => void;
}

async function streamAccounts(config: AccountStreamConfig) {
  const stream = await client.subscribeAccounts({
    accounts: config.accounts.map(a => ({
      account: a.account,
      filters: a.filters || {},
    })),
  });

  for await (const update of stream) {
    config.onUpdate({
      address: update.account,
      slot: update.slot,
      data: update.data,
      lamports: update.lamports,
      owner: update.owner,
    });
  }
}
```

### Transaction Streaming

Stream all transactions in real-time.

```typescript
async function streamTransactions(
  onTx: (tx: TransactionUpdate) => void,
) {
  const stream = await client.subscribeTransactions({
    // Filter by program or type
    accounts: [], // empty = all txs
    filters: {
      // Only confirmed transactions
      commitment: 'confirmed',
    },
  });

  for await (const tx of stream) {
    onTx({
      signature: tx.signature,
      slot: tx.slot,
      accounts: tx.accountKeys,
      instructions: tx.instructions,
      logs: tx.logMessages,
    });
  }
}
```

### Slot Streaming

Monitor slot progression and detect missed slots.

```typescript
async function streamSlots(
  onSlot: (slot: SlotUpdate) => void,
) {
  const stream = await client.subscribeSlots();

  let lastSlot = 0;

  for await (const slot of stream) {
    const missedSlots = slot.slot - lastSlot - 1;

    onSlot({
      slot: slot.slot,
      leader: slot.leader,
      missedSlots: missedSlots > 0 ? missedSlots : 0,
      timestamp: Date.now(),
    });

    lastSlot = slot.slot;
  }
}
```

## Jito Mempool

Subscribe to the Jito mempool to see pending transactions that could be backrun.

### Mempool Subscription

```typescript
import { JitoMempoolClient } from 'jito-sdk';

const mempool = new JitoMempoolClient({
  url: JITO_BLOCK_ENGINE_URL,
});

interface MempoolTx {
  signature: string;
  instructions: ParsedInstruction[];
  accounts: string[];
  programs: string[];
  timestamp: number;
}

async function subscribeMempool(
  onTx: (tx: MempoolTx) => void,
) {
  const stream = await mempool.subscribe();

  stream.on('transaction', (data: any) => {
    const tx: MempoolTx = {
      signature: data.signature,
      instructions: parseInstructions(data.transaction),
      accounts: data.transaction.message.accountKeys.map(k => k.toString()),
      programs: extractPrograms(data.transaction),
      timestamp: Date.now(),
    };

    onTx(tx);
  });
}
```

### Mempool Filtering

Filter mempool transactions for relevant opportunities.

```typescript
class MempoolFilter {
  private interestingPrograms = new Set([
    'whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc', // Orca
    'CAMMCzo5YLJw8QkntKvZVeK4x8GpGCKTHm3BWBjFkA6k', // Raydium CLMM
    'LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo', // Meteora DLMM
    'JUP6LkbZbjS1jKKwapdHX74TafTf7kFfAZBmFQ6J8xg', // Jupiter
  ]);

  filter(tx: MempoolTx): boolean {
    return tx.programs.some(p => this.interestingPrograms.has(p));
  }
}
```

### Mempool Statistics

```typescript
interface MempoolStats {
  txsPerSecond: number;
  pendingCount: number;
  topPrograms: Map<string, number>;
  averageTip: number;
}

class MempoolMonitor {
  private txCount = 0;
  private startTime = Date.now();
  private programCounts = new Map<string, number>();

  onTransaction(tx: MempoolTx) {
    this.txCount++;

    for (const program of tx.programs) {
      this.programCounts.set(
        program,
        (this.programCounts.get(program) || 0) + 1,
      );
    }
  }

  getStats(): MempoolStats {
    const elapsed = (Date.now() - this.startTime) / 1000;

    return {
      txsPerSecond: this.txCount / elapsed,
      pendingCount: this.txCount,
      topPrograms: this.programCounts,
      averageTip: 0, // from Jito API
    };
  }
}
```

## Jito Tip Floor

Monitor the current tip floor to optimize bundle pricing.

```typescript
async function getTipFloor(): Promise<{
  tipFloor: number; // in lamports per CU
  tippedCount: number;
}> {
  const response = await fetch(`${JITO_BLOCK_ENGINE}/api/v1/tip`);
  const data = await response.json();

  return {
    tipFloor: data.tipFloor,
    tippedCount: data.tippedCount,
  };
}

// Poll tip floor regularly
async function monitorTipFloor(intervalMs = 1000) {
  setInterval(async () => {
    const tipInfo = await getTipFloor();
    tipHistory.push({
      timestamp: Date.now(),
      tipFloor: tipInfo.tipFloor,
    });

    // Keep last 1000 entries
    if (tipHistory.length > 1000) {
      tipHistory.shift();
    }
  }, intervalMs);
}
```

## Transaction Lifecycle Tracking

Track a transaction from submission to finality.

```typescript
enum TxStatus {
  Submitted = 'Submitted',
  Pending = 'Pending',
  Confirmed = 'Confirmed',
  Finalized = 'Finalized',
  Failed = 'Failed',
  Dropped = 'Dropped',
}

interface TxLifecycle {
  signature: string;
  status: TxStatus;
  slot?: number;
  confirmations?: number;
  error?: string;
  timestamp: number;
  logs?: string[];
}

async function trackTransaction(
  signature: string,
  onUpdate: (update: TxLifecycle) => void,
): Promise<TxLifecycle> {
  const startTime = Date.now();
  let currentStatus: TxStatus = TxStatus.Submitted;

  onUpdate({
    signature,
    status: TxStatus.Submitted,
    timestamp: startTime,
  });

  // Poll until finalized or failed
  while (currentStatus !== TxStatus.Finalized &&
         currentStatus !== TxStatus.Failed) {
    const result = await connection.getSignatureStatus(signature);

    if (result === null) {
      currentStatus = TxStatus.Pending;
    } else if (result.err) {
      currentStatus = TxStatus.Failed;
    } else if (result.confirmations !== null && result.confirmations > 0) {
      currentStatus = TxStatus.Confirmed;
    }

    if (result?.confirmationStatus === 'finalized') {
      currentStatus = TxStatus.Finalized;
    }

    onUpdate({
      signature,
      status: currentStatus,
      slot: result?.slot,
      confirmations: result?.confirmations ?? undefined,
      error: result?.err?.toString(),
      timestamp: Date.now(),
    });

    // Timeout after 60 seconds
    if (Date.now() - startTime > 60000) {
      currentStatus = TxStatus.Dropped;
      break;
    }

    await sleep(500);
  }

  return {
    signature,
    status: currentStatus,
    timestamp: Date.now(),
  };
}
```

## Performance Monitoring

### Metrics to Track

```typescript
interface BotMetrics {
  slotsTracked: number;
  txsAnalyzed: number;
  bundlesSubmitted: number;
  bundlesLanded: number;
  totalProfit: number;
  totalTips: number;
  latencyMs: {
    detection: number;  // from gRPC to opportunity detected
    execution: number;  // from detection to bundle submission
    confirmation: number; // from submission to landing
  };
  errorRate: number;
}
```

### Alerting

```typescript
function checkAlerts(metrics: BotMetrics) {
  if (metrics.bundlesSubmitted > 0 &&
      metrics.bundlesLanded / metrics.bundlesSubmitted < 0.5) {
    alert('Warning: Low bundle landing rate (< 50%)');
  }

  if (metrics.errorRate > 0.1) {
    alert('Error: Error rate exceeds 10%');
  }

  if (metrics.latencyMs.execution > 200) {
    alert('Warning: High execution latency (> 200ms)');
  }
}
```

---

**Related skills:**
- [jito-bundles.md](jito-bundles.md) — Bundle submission
- [arbitrage.md](arbitrage.md) — Price monitoring for arb detection
- [liquidations.md](liquidations.md) — Position monitoring via gRPC
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
