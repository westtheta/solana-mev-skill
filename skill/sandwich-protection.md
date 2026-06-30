# Sandwich Protection

Understanding sandwich attacks on Solana and how to protect user transactions. This skill is for **defensive** purposes — preventing MEV extraction, not performing it.

---

## What Is a Sandwich Attack?

A sandwich attack is a form of MEV extraction where a malicious actor places two transactions around a user's transaction:

```
Before: Buy large amount → price goes up
Target: User's swap executes at inflated price
After:  Sell at inflated price → profit
```

### Sandwich Anatomy on Solana

```
Block:
┌─────────────────────────────────────────────────────┐
│  Slot N                                              │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Sandwich │  │  User's  │  │ Sandwich │           │
│  │  Front   │  │    Tx    │  │   Back   │           │
│  │  (buy)   │  │  (swap)  │  │  (sell)  │           │
│  └──────────┘  └──────────┘  └──────────┘           │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## How Sandwiching Works on Solana

### Detection Phase

The attacker detects a pending transaction (usually a large swap) via:

1. **Jito Mempool** — If a user submits through the regular RPC, their tx may appear in Jito's mempool
2. **Gossip** — Transactions propagate through the cluster before being included

### Frontrun Phase

The attacker submits a buy transaction before the user's, driving the price up.

### Execution Phase

The user's transaction executes at the worse price (higher slippage than expected).

### Backrun Phase

The attacker sells immediately after, capturing the profit from the price movement.

## Identifying Sandwich Attacks

### On-Chain Detection

```typescript
interface SandwichPattern {
  victim: PublicKey;
  attacker: PublicKey;
  token: string;
  profit: number;
  frontrunTx: string;
  victimTx: string;
  backrunTx: string;
  block: number;
}

async function detectSandwich(
  txSignature: string,
): Promise<SandwichPattern | null> {
  const tx = await connection.getTransaction(txSignature);

  // Check if this tx was sandwiched
  const { slot } = tx;
  const block = await connection.getBlock(slot);

  // Find all swaps in the same block
  const swaps = block.transactions.filter(isSwapTransaction);

  // Look for buy-before and sell-after pattern
  const ourIndex = swaps.findIndex(s => s.signature === txSignature);

  if (ourIndex > 0 && ourIndex < swaps.length - 1) {
    const before = swaps[ourIndex - 1];
    const after = swaps[ourIndex + 1];

    // Check if before is buy, after is sell of same token
    if (isBuy(before) && isSell(after) && sameToken(before, after)) {
      return {
        victim: tx.accountKeys[0],
        attacker: before.accountKeys[0],
        token: extractToken(before),
        profit: calculateProfit(before, after),
        frontrunTx: before.signature,
        victimTx: txSignature,
        backrunTx: after.signature,
        block: slot,
      };
    }
  }

  return null;
}
```

## Protecting User Transactions

### Method 1: Jito Bundle Protection (Recommended)

Wrap user transactions in a Jito bundle to prevent sandwiching.

```typescript
async function protectSwap(
  swapTx: VersionedTransaction,
  wallet: Keypair,
): Promise<string> {
  // Wrap in a Jito bundle with only the user's tx
  // This ensures no tx can be inserted before or after
  const bundle = new Bundle()
    .addTransaction(swapTx)
    .setTip(0.0001); // Small tip for inclusion

  return submitBundle(bundle);
}
```

### Method 2: Jito Bundle with Co-location

Submit the user's transaction alongside your own protective transactions.

```typescript
async function protectWithCollateral(
  swapTx: VersionedTransaction,
  protectorWallet: Keypair,
  bundleAmount: number,
): Promise<string> {
  const tipAccount = Keypair.generate();

  const protectBundle = new Bundle()
    .addTransaction(swapTx) // User's swap
    .setTip(bundleAmount, tipAccount.publicKey);

  return submitBundle(protectBundle);
}
```

### Method 3: Slippage Protection

Set tight slippage bounds so sandwiching becomes unprofitable.

```typescript
interface SwapParams {
  inputAmount: number;
  expectedOutput: number;
  slippageBps: number; // basis points (e.g., 50 = 0.5%)
  minOutputAmount: number;
}

function calculateMinOutput(
  expectedOutput: number,
  slippageBps: number,
): number {
  return expectedOutput * (1 - slippageBps / 10000);
}

// For sandwich-prone tokens (low liquidity), use lower slippage
const SLIPPAGE_CONFIG = {
  'high-liquidity': 30, // 0.3%
  'medium-liquidity': 50, // 0.5%
  'low-liquidity': 100, // 1.0%
};
```

### Method 4: MEV-Aware Routing (Jupiter)

Use Jupiter's MEV-aware routing for swaps.

```typescript
import { Jupiter } from '@jup-ag/api';

async function swapWithMEVProtection(
  inputMint: string,
  outputMint: string,
  amount: number,
  wallet: PublicKey,
): Promise<VersionedTransaction> {
  const jupiter = new Jupiter();

  const quote = await jupiter.quote({
    inputMint,
    outputMint,
    amount,
    slippageBps: 50,
    // dynamicSlippage: true, // Jupiter's MEV-aware slippage
    // computeAutoSlippage: true,
  });

  // Jupiter automatically routes through the best path
  // and can use Jito bundles for protection
  const { swapTransaction } = await jupiter.swap({
    quoteResponse: quote,
    userPublicKey: wallet.toString(),
    // Use Jito bundle for protection
    wrapAndUnwrapSol: true,
    dynamicComputeUnitLimit: true,
  });

  return VersionedTransaction.deserialize(
    Buffer.from(swapTransaction, 'base64'),
  );
}
```

## Detecting Risky Swaps

### Risk Scoring for Swaps

```typescript
interface SwapRisk {
  score: number; // 0-100
  factors: {
    lowLiquidity: boolean;
    largeAmount: boolean;
    highSlippage: boolean;
    unpopularToken: boolean;
    recentSandwichActivity: boolean;
  };
}

function assessSwapRisk(
  swap: {
    token: string;
    amount: number;
    slippage: number;
    dex: string;
  },
): SwapRisk {
  let score = 0;
  const factors = {
    lowLiquidity: false,
    largeAmount: false,
    highSlippage: false,
    unpopularToken: false,
    recentSandwichActivity: false,
  };

  // Check liquidity
  if (swap.amount > MAX_SWAP_WITHOUT_CHECK) {
    factors.largeAmount = true;
    score += 30;
  }

  // Check slippage
  if (swap.slippage > SAFE_SLIPPAGE) {
    factors.highSlippage = true;
    score += 25;
  }

  // Check if token is frequently sandwiched
  if (isFrequentlySandwiched(swap.token)) {
    factors.recentSandwichActivity = true;
    score += 25;
  }

  return { score: Math.min(100, score), factors };
}
```

### Liquidity Check

```typescript
async function checkLiquidity(
  tokenMint: string,
  dex: string,
): Promise<{
  adequate: boolean;
  depthUsd: number;
  recommendation: string;
}> {
  const depth = await getPoolDepth(tokenMint, dex);

  return {
    adequate: depth > MIN_LIQUIDITY_USD,
    depthUsd: depth,
    recommendation: depth > 100000
      ? 'Safe'
      : depth > 50000
      ? 'Caution'
      : 'High risk of sandwich',
  };
}
```

## MEV Protection for dApps

### Integrating Protection into Your dApp

```typescript
class MEVProtectionService {
  async submitProtectedTransaction(
    instructions: TransactionInstruction[],
    wallet: Keypair,
    options?: {
      useBundle?: boolean;
      maxTip?: number;
      slippageBps?: number;
    },
  ): Promise<string> {
    if (options?.useBundle ?? true) {
      // Submit via Jito bundle for protection
      const tx = await buildVersionedTx(instructions, wallet);
      return this.submitBundle(tx, options?.maxTip);
    } else {
      // Direct RPC submission (riskier)
      const tx = await buildVersionedTx(instructions, wallet);
      return connection.sendTransaction(tx);
    }
  }
}
```

### User-Facing MEV Warnings

```typescript
function getMEVWarning(riskScore: number): string {
  if (riskScore >= 75) {
    return '🚨 High risk of MEV extraction. Consider using Jito bundle protection.';
  } else if (riskScore >= 50) {
    return '⚠️ Moderate MEV risk. Lower slippage or use protected submission.';
  } else if (riskScore >= 25) {
    return 'ℹ️ Low MEV risk. Standard submission should be safe.';
  }
  return '✅ Minimal MEV risk.';
}
```

## Compliance & Ethics

**Important:** Sandwich attacks extract value from users and damage the Solana ecosystem.

| Action | Ethical | Legal Risk |
|--------|---------|------------|
| **Performing sandwich attacks** | ❌ No | Potential regulatory risk |
| **Protecting users from sandwiches** | ✅ Yes | None |
| **Building sandwich detection** | ✅ Yes (defensive) | None |
| **Researching sandwich mechanics** | ✅ Yes (academic) | None |
| **Building user-facing MEV warnings** | ✅ Yes | None |

---

**Related skills:**
- [jito-bundles.md](jito-bundles.md) — Bundle submission for protection
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
- [arbitrage.md](arbitrage.md) — Understanding related MEV types
- [mev-risk-analysis.md](mev-risk-analysis.md) — Risk scoring
