# MEV Risk Analysis

Transaction risk scoring, MEV forensics, and analysis tools for detecting and measuring MEV extraction on Solana.

---

## Transaction Risk Scoring

Score any Solana transaction for MEV risk on a 0-100 scale.

```typescript
interface MEVRiskScore {
  overall: number; // 0-100
  factors: {
    frontrunRisk: number; // 0-100
    backrunRisk: number; // 0-100
    sandwichRisk: number; // 0-100
    jitoMempoolExposure: number; // 0-100
  };
  details: {
    detectedPatterns: string[];
    suspiciousAccounts: string[];
    profitExtracted: number;
  };
}
```

### Scoring Algorithm

```typescript
async function scoreTransaction(
  signature: string,
): Promise<MEVRiskScore> {
  const tx = await connection.getTransaction(signature, {
    maxSupportedTransactionVersion: 0,
  });

  if (!tx) throw new Error('Transaction not found');

  // Analyze the transaction
  const swapAnalysis = analyzeSwapInstructions(tx);
  const accountAnalysis = analyzeAccounts(tx);
  const timingAnalysis = await analyzeTiming(tx);

  // Calculate risk factors
  const frontrunRisk = calculateFrontrunRisk(swapAnalysis, timingAnalysis);
  const backrunRisk = calculateBackrunRisk(swapAnalysis, timingAnalysis);
  const sandwichRisk = calculateSandwichRisk(swapAnalysis, accountAnalysis);
  const mempoolExposure = calculateMempoolExposure(swapAnalysis);

  // Overall weighted score
  const overall = Math.min(100,
    frontrunRisk * 0.25 +
    backrunRisk * 0.25 +
    sandwichRisk * 0.35 +
    mempoolExposure * 0.15
  );

  return {
    overall: Math.round(overall),
    factors: {
      frontrunRisk: Math.round(frontrunRisk),
      backrunRisk: Math.round(backrunRisk),
      sandwichRisk: Math.round(sandwichRisk),
      jitoMempoolExposure: Math.round(mempoolExposure),
    },
    details: {
      detectedPatterns: detectPatterns(tx),
      suspiciousAccounts: accountAnalysis.suspicious,
      profitExtracted: accountAnalysis.extractedValue,
    },
  };
}
```

### Risk Factors

| Factor | Weight | Detection Method |
|--------|--------|-----------------|
| **Large swap amount** | 30% | Amount relative to pool liquidity |
| **Low pool liquidity** | 25% | Pool depth in USD |
| **High slippage tolerance** | 25% | Slippage settings on swap |
| **Rare token** | 10% | Token age, volume, holders |
| **Unprotected submission** | 10% | Direct RPC vs Jito bundle |

## MEV Forensics

Analyze historical transactions to detect MEV extraction.

### Detect MEV in a Block

```typescript
interface BlockMEVReport {
  slot: number;
  totalMEVExtracted: number;
  sandwiches: SandwichPattern[];
  arbitrages: ArbPattern[];
  liquidations: LiquidationPattern[];
  backruns: BackrunPattern[];
}

async function analyzeBlock(
  slot: number,
): Promise<BlockMEVReport> {
  const block = await connection.getBlock(slot);

  const sandwiches: SandwichPattern[] = [];
  const arbitrages: ArbPattern[] = [];
  const liquidations: LiquidationPattern[] = [];
  const backruns: BackrunPattern[] = [];

  // Analyze each transaction in the block
  const txs = block.transactions.filter(tx => !tx.meta?.err);

  for (let i = 1; i < txs.length - 1; i++) {
    // Check for sandwich patterns
    const sandwich = await detectSandwichPattern(txs, i);
    if (sandwich) sandwiches.push(sandwich);

    // Check for arbitrage
    const arb = await detectArbitragePattern(txs[i]);
    if (arb) arbitrages.push(arb);

    // Check for liquidation
    const liq = await detectLiquidationPattern(txs[i]);
    if (liq) liquidations.push(liq);

    // Check for backrunning
    const back = await detectBackrunPattern(txs, i);
    if (back) backruns.push(back);
  }

  return {
    slot,
    totalMEVExtracted: calculateTotalMEV({ sandwiches, arbitrages, liquidations }),
    sandwiches,
    arbitrages,
    liquidations,
    backruns,
  };
}
```

### MEV Extraction Calculation

```typescript
interface MEVExtraction {
  type: 'sandwich' | 'arbitrage' | 'liquidation';
  profit: number; // in SOL or USD
  confidence: number; // 0-1
  txSignature: string;
}

function calculateSandwichProfit(
  frontrun: ParsedTransaction,
  backrun: ParsedTransaction,
): number {
  // Frontrun buy amount
  const buyAmount = frontrun.meta!.postBalances[frontrun.meta!.preBalances.length - 1]
    - frontrun.meta!.preBalances[frontrun.meta!.preBalances.length - 1];

  // Backrun sell amount
  const sellAmount = backrun.meta!.postBalances[0] - backrun.meta!.preBalances[0];

  return sellAmount - buyAmount;
}
```

## Jito Bundle Analysis

### Detect if a Transaction Used Jito

```typescript
async function detectJitoUsage(
  signature: string,
): Promise<boolean> {
  const tx = await connection.getTransaction(signature);

  // Check for Jito tip account
  const jitoTipAccounts = [
    '96gYZGDn1bYYoL6N5BmBFTJtmw2c6F3bCxHJkY8rrcLn',
    'FbC1P7mnPBhP8pYLsYBjYAWiJFM7JZn5BKzRgKXrWCCf',
  ];

  // Check if any instruction transfers to a Jito tip account
  for (const ix of tx.transaction.message.instructions) {
    if (ix.programId.equals(SystemProgram.programId)) {
      // Check for tip account
    }
  }

  return false;
}
```

### Tip Analysis

```typescript
interface TipAnalysis {
  tipAmount: number;
  tipAccount: string;
  bundleId: string | null;
  slot: number;
  wasSelected: boolean;
}

async function analyzeTip(
  signature: string,
): Promise<TipAnalysis | null> {
  // Jito bundles have unique tip accounts
  // Check if the tip account was newly created and immediately closed
  const tx = await connection.getTransaction(signature);

  // First tx of bundle creates tip account
  // Last tx of bundle drains it

  return null; // Not a Jito bundle
}
```

## MEV Dashboard

### Metrics to Monitor

```typescript
interface MEVDashboard {
  overview: {
    totalExtracted: number; // USD
    totalBundles: number;
    totalSearchers: number;
    avgTip: number; // SOL
  };
  byType: {
    sandwiches: number;
    arbitrages: number;
    liquidations: number;
    backruns: number;
  };
  topPrograms: {
    program: string;
    mevVolume: number;
    pctOfTotal: number;
  }[];
  recentBlocks: BlockMEVReport[];
}
```

### Real-Time Dashboard

```typescript
class MEVAnalyzer {
  private reports: BlockMEVReport[] = [];

  async startMonitoring() {
    const stream = await createGrpcStream(GRPC_ENDPOINT);

    stream.on('block', async (slot: number) => {
      const report = await analyzeBlock(slot);
      this.reports.push(report);

      // Keep last 100 blocks
      if (this.reports.length > 100) {
        this.reports.shift();
      }

      console.log(`Block ${slot}: ${report.totalMEVExtracted} SOL extracted`);
    });
  }

  getTopSearchers(): Map<string, number> {
    const searchers = new Map<string, number>();

    for (const report of this.reports) {
      for (const tx of [...report.sandwiches, ...report.arbitrages]) {
        const address = tx.attacker?.toString() || 'unknown';
        searchers.set(address, (searchers.get(address) || 0) + tx.profit);
      }
    }

    return searchers;
  }
}
```

## Compliance Reporting

### MEV Activity Report

```typescript
interface ComplianceReport {
  timeframe: { start: Date; end: Date };
  totalTransactions: number;
  mevAffectedTransactions: number;
  mevPercentage: number;
  totalValueExtracted: number;
  protocols: {
    name: string;
    mevVolume: number;
    protectionEnabled: boolean;
  }[];
  recommendations: string[];
}
```

### Check if an Address is a Known Searcher

```typescript
const KNOWN_SEARCHERS = new Map([
  ['7tVucp...', 'Flash Arbitrage'],
  ['3xHw9b...', 'Arbitrage Bot'],
  ['J2Rj3K...', 'Liquidation Bot'],
]);

async function identifySearcher(
  address: PublicKey,
): Promise<string | null> {
  // Check known database
  if (KNOWN_SEARCHERS.has(address.toString())) {
    return KNOWN_SEARCHERS.get(address.toString())!;
  }

  // Analyze behavior patterns
  const txHistory = await connection.getSignaturesForAddress(address, { limit: 100 });
  const patterns = analyzeTxPatterns(txHistory);

  if (patterns.includes('arbitrage')) return 'Unknown Arbitrageur';
  if (patterns.includes('liquidation')) return 'Unknown Liquidator';
  if (patterns.includes('sandwich')) return 'Unknown Sandwich Attacker';

  return null;
}
```

## Best Practices

### For dApp Developers

1. **Use Jito bundles** — Always offer bundle submission for user swaps
2. **Dynamic slippage** — Adjust slippage based on MEV conditions
3. **MEV warnings** — Warn users when their tx is at risk
4. **Monitor your protocol** — Track how much MEV is extracted from your users

### For Searchers

1. **Simulate everything** — Never submit untested bundles
2. **Track your PnL** — Gross profit ≠ net profit after tips and fees
3. **Diversify strategies** — Don't rely on a single MEV type
4. **Stay ethical** — Sandwiches hurt the ecosystem long-term

---

**Related skills:**
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
- [sandwich-protection.md](sandwich-protection.md) — Sandwich detection
- [jito-bundles.md](jito-bundles.md) — Bundle analysis
- [mempool-monitoring.md](mempool-monitoring.md) — Monitoring infrastructure
