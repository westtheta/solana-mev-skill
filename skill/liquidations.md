# Liquidation Opportunities

Detect and execute liquidations on Solana lending protocols. Monitor undercollateralized positions and claim liquidation bonuses.

---

## Overview

When a borrower's position becomes undercollateralized (health factor < 1), anyone can liquidate it. The liquidator repays some or all of the debt and receives the collateral at a bonus discount.

### Supported Protocols

| Protocol | Liquidation Bonus | Oracle | Program ID |
|----------|------------------|--------|------------|
| **Kamino** | 5-10% | Pyth + Switchboard | `KLend...` |
| **Marginfi** | 5-8% | Pyth | `MFv2...` |
| **Save (ex-Solend)** | 5-10% | Pyth + Switchboard | `So1en...` |

## Liquidation Detection

### Health Factor Monitoring

Health factor = (collateral value × liquidation threshold) / debt value

- **HF > 1** — Healthy position
- **HF ≈ 1** — At risk
- **HF < 1** — Liquidatable

```typescript
interface Position {
  owner: PublicKey;
  protocol: 'kamino' | 'marginfi' | 'save';
  healthFactor: number;
  debt: {
    mint: string;
    amount: number;
    valueUsd: number;
  };
  collateral: {
    mint: string;
    amount: number;
    valueUsd: number;
  };
  estimatedProfit: number;
  timestamp: number;
}
```

### Yellowstone gRPC Subscription

Stream lending protocol accounts in real-time to detect health factor changes.

```typescript
import { createGrpcStream } from 'yellowstone-grpc';

async function monitorLiquidations(
  protocolAccounts: string[],
  onLiquidation: (position: Position) => void,
) {
  const stream = await createGrpcStream({
    endpoint: GRPC_ENDPOINT,
    accounts: protocolAccounts.map(account => ({
      account,
      filters: {}, // no additional filters
    })),
  });

  stream.on('data', async (update: AccountUpdate) => {
    const position = parsePosition(update);
    if (position.healthFactor < 1) {
      onLiquidation(position);
    }
  });
}
```

### Manual Health Factor Check

```typescript
async function checkHealthFactor(
  protocol: 'kamino' | 'marginfi' | 'save',
  obligationAccount: PublicKey,
): Promise<number> {
  switch (protocol) {
    case 'kamino':
      return checkKaminoHealth(obligationAccount);
    case 'marginfi':
      return checkMarginfiHealth(obligationAccount);
    case 'save':
      return checkSaveHealth(obligationAccount);
  }
}
```

## Profit Calculation

```typescript
interface LiquidationProfit {
  debtToRepay: number; // in debt token
  collateralToReceive: number; // in collateral token
  liquidationBonus: number; // percentage
  grossProfitUsd: number;
  fees: {
    priorityFee: number;
    jitoTip: number;
    total: number;
  };
  netProfitUsd: number;
}

function calculateLiquidationProfit(
  position: Position,
  maxLiquidationPct: number,
): LiquidationProfit {
  const debtToRepay = position.debt.valueUsd * maxLiquidationPct;
  const bonus = position.protocol === 'kamino' ? 0.08 : 0.05;

  const collateralValue = position.collateral.valueUsd;
  const collateralToReceive = (debtToRepay * (1 + bonus)) / collateralValue;

  const fees = estimateFees();
  const grossProfit = debtToRepay * bonus;
  const netProfit = grossProfit - fees.total;

  return {
    debtToRepay,
    collateralToReceive,
    liquidationBonus: bonus,
    grossProfitUsd: grossProfit,
    fees,
    netProfitUsd: netProfit,
  };
}
```

## Liquidation Execution

### Kamino Liquidation

```typescript
async function liquidateKamino(
  position: Position,
  wallet: Keypair,
): Promise<string> {
  // Build liquidation instruction
  const liquidateIx = await buildKaminoLiquidateIx({
    obligation: position.owner,
    debtMint: position.debt.mint,
    collateralMint: position.collateral.mint,
    maxRepayAmount: calculateRepayAmount(position),
  });

  // Build bundle for atomic execution
  const bundle = new Bundle()
    .addTransaction(await buildVersionedTx([liquidateIx], wallet))
    .setTip(calculateLiquidationTip(position.estimatedProfit));

  return submitBundle(bundle);
}
```

### Marginfi Liquidation

```typescript
async function liquidateMarginfi(
  position: Position,
  wallet: Keypair,
): Promise<string> {
  const liquidateIx = await buildMarginfiLiquidateIx({
    bank: position.debt.mint,
    liquidatorBank: position.collateral.mint,
    account: position.owner,
    assetAmount: calculateRepayAmount(position),
  });

  const bundle = new Bundle()
    .addTransaction(await buildVersionedTx([liquidateIx], wallet))
    .setTip(calculateLiquidationTip(position.estimatedProfit));

  return submitBundle(bundle);
}
```

## Racing Strategy

Liquidations are competitive — the first searcher to submit wins. Speed is critical.

### Architecture for Speed

```
                     ┌─────────────────┐
   Yellowstone gRPC  │  Position       │
   ───────────────►  │  Monitor        │
                     └────────┬────────┘
                              │ position detected
                              ▼
                     ┌─────────────────┐
                     │  Profit         │
                     │  Calculator     │
                     └────────┬────────┘
                              │ profitable
                              ▼
                     ┌─────────────────┐
                     │  Bundle Builder │
                     │  (pre-built)    │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  Jito Block     │
                     │  Engine         │
                     └─────────────────┘
```

### Pre-Built Bundles

Pre-build liquidation bundles with only the amount and account as variables.

```typescript
// Build skeleton bundle once, parameterize amounts
function buildLiquidationSkeleton(
  protocol: string,
  wallet: Keypair,
): BundleSkeleton {
  const tipAccount = Keypair.generate();
  const blockhash = await connection.getLatestBlockhash();

  return {
    blockhash,
    protocol,
    tipAccount,
    wallet,
  };
}

// Fill in amounts when opportunity is detected
function fillLiquidationBundle(
  skeleton: BundleSkeleton,
  position: Position,
): Bundle {
  return skeleton.builder
    .setAmount(calculateRepayAmount(position))
    .setTip(calculateLiquidationTip(position.estimatedProfit))
    .build();
}
```

## Risk Management

### Profit Threshold

```typescript
function shouldLiquidate(
  position: Position,
  config: {
    minProfitUsd: number;
    maxJitoTip: number;
  },
): boolean {
  const profit = calculateLiquidationProfit(position, 0.5);

  if (profit.netProfitUsd < config.minProfitUsd) return false;
  if (profit.fees.jitoTip > config.maxJitoTip) return false;
  if (position.healthFactor > 0.98) return false; // too close, might miss

  return true;
}
```

### Competition Analysis

```typescript
async function estimateCompetition(
  protocol: string,
): Promise<'Low' | 'Medium' | 'High'> {
  // Check recent liquidation frequency
  const recentLiquidations = await getRecentLiquidations(protocol, 100);
  const avgTimeBetween = getAverageTimeBetween(recentLiquidations);

  if (avgTimeBetween < 5) return 'High'; // < 5 seconds between liquidations
  if (avgTimeBetween < 30) return 'Medium';
  return 'Low';
}
```

## Testing on Devnet

Always test liquidation bots on devnet first.

```typescript
async function testLiquidation() {
  // 1. Create a position on devnet
  const position = await createTestPosition({
    collateral: 1000, // USDC
    debt: 800, // SOL
  });

  // 2. Manipulate oracle to drop health factor
  await setOraclePrice('SOL/USDC', 15); // Drop SOL price

  // 3. Verify position is liquidatable
  const hf = await checkHealthFactor('kamino', position.obligation);
  console.assert(hf < 1, 'Position should be liquidatable');

  // 4. Execute liquidation
  const sig = await liquidateKamino({ owner: position.owner, ... }, wallet);
  console.log(`Liquidation tx: ${sig}`);
}
```

---

**Related skills:**
- [jito-bundles.md](jito-bundles.md) — Bundle submission for liquidation txs
- [mempool-monitoring.md](mempool-monitoring.md) — gRPC streaming for position monitoring
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
- [mev-risk-analysis.md](mev-risk-analysis.md) — Risk scoring
