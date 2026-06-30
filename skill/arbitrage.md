# DEX Arbitrage Detection & Execution

Cross-DEX and triangular arbitrage detection on Solana. Scan multiple DEXes for price discrepancies and execute atomic arbitrage via Jito bundles.

---

## Arbitrage Types

### 1. Cross-DEX Arbitrage

Buy token A on DEX X, sell token A on DEX Y. The simplest and most common arb.

```
Orca:   1 SOL = 99.5 USDC
Raydium: 1 SOL = 100.5 USDC
Profit: 1 USDC per SOL (minus fees)
```

### 2. Triangular Arbitrage

Trade through three or more pairs in a loop to end up with more of the starting token.

```
SOL → USDC → BONK → SOL
If USDC/SOL × BONK/USDC × SOL/BONK > 1 → opportunity
```

### 3. Flash Loan Arbitrage

Borrow capital via flash loan, execute arb, repay loan — all in one atomic transaction.

## Arbitrage Detection

### Price Fetching

```typescript
interface DexPrice {
  dex: string;
  tokenIn: string;
  tokenOut: string;
  price: number; // tokenOut per tokenIn
  liquidity: number; // in USD
  fee: number; // DEX fee (e.g., 0.003 for 0.3%)
}

interface ArbOpportunity {
  buyDex: DexPrice;
  sellDex: DexPrice;
  expectedProfit: number;
  profitAfterFees: number;
  confidence: number; // 0-1
}
```

### Cross-DEX Scanner

```typescript
import { WhirlpoolClient } from '@orca-so/whirlpools-sdk';
import { Jupiter } from '@jup-ag/api';

async function scanCrossDex(
  tokenMint: string,
  amount: number,
): Promise<ArbOpportunity[]> {
  const opportunities: ArbOpportunity[] = [];

  // Fetch prices from multiple DEXes
  const [orcaPrice, raydiumPrice, meteoraPrice] = await Promise.all([
    getOrcaPrice(tokenMint),
    getRaydiumPrice(tokenMint),
    getMeteoraPrice(tokenMint),
  ]);

  const prices = [orcaPrice, raydiumPrice, meteoraPrice].filter(Boolean);

  // Find profitable pairs
  for (let i = 0; i < prices.length; i++) {
    for (let j = 0; j < prices.length; j++) {
      if (i === j) continue;

      const buyDex = prices[i];
      const sellDex = prices[j];
      const grossProfit = (sellDex.price - buyDex.price) * amount;
      const fees = amount * buyDex.fee * buyDex.price + amount * sellDex.fee;

      const netProfit = grossProfit - fees;

      if (netProfit > MIN_PROFIT) {
        opportunities.push({
          buyDex: buyDex.dex === 'orca' ? orcaPrice! : raydiumPrice!,
          sellDex: sellDex.dex === 'orca' ? orcaPrice! : raydiumPrice!,
          expectedProfit: grossProfit,
          profitAfterFees: netProfit,
          confidence: calculateConfidence(buyDex, sellDex),
        });
      }
    }
  }

  return opportunities.sort((a, b) => b.profitAfterFees - a.profitAfterFees);
}
```

### Triangular Arbitrage Scanner

```typescript
interface TrianglePath {
  tokens: string[]; // e.g., [SOL, USDC, BONK]
  rates: number[];  // exchange rates along the path
  product: number;  // product of rates (> 1 = profitable)
}

async function findTriangularArb(
  baseToken: string,
): Promise<TrianglePath[]> {
  const opportunities: TrianglePath[] = [];

  // Get all tradable pairs from price oracle
  const pairs = await getAllPairs(baseToken);

  // Find cycles of length 3
  for (const pair1 of pairs) {
    const intermediateToken = pair1.tokenOut;

    for (const pair2 of pairs.filter(p => p.tokenIn === intermediateToken)) {
      const finalToken = pair2.tokenOut;

      for (const pair3 of pairs.filter(
        p => p.tokenIn === finalToken && p.tokenOut === baseToken,
      )) {
        const product = pair1.rate * pair2.rate * pair3.rate;

        if (product > 1.0 + TRIANGULAR_THRESHOLD) {
          opportunities.push({
            tokens: [baseToken, intermediateToken, finalToken],
            rates: [pair1.rate, pair2.rate, pair3.rate],
            product,
          });
        }
      }
    }
  }

  return opportunities;
}
```

## Profit Calculation

Always account for ALL costs:

```typescript
interface ProfitCalc {
  grossProfit: number;
  buyDexFee: number;
  sellDexFee: number;
  jitoTip: number;
  priorityFee: number;
  netProfit: number;
  roi: number; // netProfit / capital
}

function calculateProfit(
  capital: number,
  buyPrice: number,
  sellPrice: number,
  buyFee: number,
  sellFee: number,
): ProfitCalc {
  const grossProfit = (sellPrice - buyPrice) * capital;
  const buyDexFee = capital * buyPrice * buyFee;
  const sellDexFee = capital * sellFee;
  const jitoTip = estimateTip(); // from tip history
  const priorityFee = estimatePriorityFee();
  const totalCost = buyDexFee + sellDexFee + jitoTip + priorityFee;
  const netProfit = grossProfit - totalCost;

  return {
    grossProfit,
    buyDexFee,
    sellDexFee,
    jitoTip,
    priorityFee,
    netProfit,
    roi: netProfit / capital,
  };
}
```

## Execution Strategy

### Atomic Arbitrage via Jito Bundle

```typescript
async function executeAtomicArb(
  opportunity: ArbOpportunity,
  wallet: Keypair,
): Promise<string> {
  // 1. Build buy tx
  const buyIx = await buildSwapInstruction(
    opportunity.buyDex,
    'in', // direction: buy
    opportunity.tokenIn,
    opportunity.tokenOut,
    AMOUNT,
  );

  // 2. Build sell tx
  const sellIx = await buildSwapInstruction(
    opportunity.sellDex,
    'out', // direction: sell
    opportunity.tokenOut,
    opportunity.tokenIn,
    AMOUNT,
  );

  // 3. Build bundle
  const bundle = new Bundle()
    .addTransaction(await buildVersionedTx([buyIx], wallet))
    .addTransaction(await buildVersionedTx([sellIx], wallet))
    .setTip(calculateTip(opportunity.profitAfterFees));

  // 4. Simulate
  const simResult = await simulateBundle(bundle);
  if (!simResult.willSucceed) {
    throw new Error(`Bundle simulation failed: ${simResult.logs}`);
  }

  // 5. Submit
  return submitBundle(bundle);
}
```

### Jupiter Integration

Jupiter API can be used for routing and price quotes.

```typescript
import { Jupiter } from '@jup-ag/api';

const jupiter = new Jupiter();

async function getJupiterQuote(
  inputMint: string,
  outputMint: string,
  amount: number,
): Promise<QuoteResponse> {
  return jupiter.quote({
    inputMint,
    outputMint,
    amount,
    slippageBps: 50, // 0.5%
  });
}

async function buildJupiterSwapTx(
  quote: QuoteResponse,
  wallet: PublicKey,
): Promise<VersionedTransaction> {
  const { swapTransaction } = await jupiter.swap({
    quoteResponse: quote,
    userPublicKey: wallet.toString(),
  });

  return VersionedTransaction.deserialize(Buffer.from(swapTransaction, 'base64'));
}
```

## DEX-Specific Integration

### Orca Whirlpools

```typescript
import { WhirlpoolClient, ORCA_WHIRLPOOLS_PROGRAM_ID } from '@orca-so/whirlpools-sdk';

async function getOrcaPrice(
  tokenMint: string,
): Promise<DexPrice | null> {
  const client = new WhirlpoolClient(connection);
  const pools = await client.getPoolsForToken(tokenMint);

  if (pools.length === 0) return null;

  const pool = pools[0];
  const price = pool.getPrice();

  return {
    dex: 'orca',
    tokenIn: tokenMint,
    tokenOut: pool.tokenB.mint.toString(),
    price,
    liquidity: await pool.getLiquidityUsd(),
    fee: pool.feeRate,
  };
}
```

### Meteora DLMM

```typescript
import { DLMM } from '@meteora-ag/dlmm';

async function getMeteoraPrice(
  tokenMint: string,
): Promise<DexPrice | null> {
  const dlmmPools = await DLMM.getPoolsByToken(connection, tokenMint);

  if (dlmmPools.length === 0) return null;

  const pool = dlmmPools[0];
  const price = pool.getSpotPrice();

  return {
    dex: 'meteora',
    tokenIn: tokenMint,
    tokenOut: pool.tokenY.mint.toString(),
    price,
    liquidity: pool.liquidityUsd,
    fee: pool.feeBps / 10000,
  };
}
```

## Performance Optimization

### Batch Price Fetching

```typescript
async function batchFetchPrices(
  tokens: string[],
  dexes: string[],
): Promise<Map<string, DexPrice[]>> {
  const results = new Map<string, DexPrice[]>();

  const pricePromises = tokens.flatMap(token =>
    dexes.map(dex => fetchPrice(dex, token)),
  );

  const prices = await Promise.allSettled(pricePromises);

  prices.forEach((result, i) => {
    if (result.status === 'fulfilled' && result.value) {
      const token = tokens[Math.floor(i / dexes.length)];
      if (!results.has(token)) results.set(token, []);
      results.get(token)!.push(result.value);
    }
  });

  return results;
}
```

### Caching

```typescript
class PriceCache {
  private cache = new Map<string, { price: number; timestamp: number }>();
  private ttl = 200; // 200ms cache (half a slot)

  get(token: string, dex: string): number | null {
    const key = `${token}:${dex}`;
    const entry = this.cache.get(key);
    if (entry && Date.now() - entry.timestamp < this.ttl) {
      return entry.price;
    }
    return null;
  }

  set(token: string, dex: string, price: number): void {
    const key = `${token}:${dex}`;
    this.cache.set(key, { price, timestamp: Date.now() });
  }
}
```

## Risk Management

### Slippage Protection

```typescript
function checkSlippage(
  expectedPrice: number,
  actualPrice: number,
  maxSlippage: number,
): boolean {
  const slippage = Math.abs(actualPrice - expectedPrice) / expectedPrice;
  return slippage <= maxSlippage;
}
```

### Minimum Profit Threshold

```typescript
const MIN_PROFIT_SOL = 0.01; // 0.01 SOL minimum
const MIN_ROI = 0.001; // 0.1% minimum ROI
```

### Confidence Scoring

```typescript
function calculateConfidence(
  buyDex: DexPrice,
  sellDex: DexPrice,
): number {
  let score = 1.0;

  // Reduce confidence if liquidity is low
  if (buyDex.liquidity < 10000) score *= 0.5;
  if (sellDex.liquidity < 10000) score *= 0.5;

  // Reduce confidence if price difference is small
  const priceDiff = Math.abs(sellDex.price - buyDex.price) / buyDex.price;
  if (priceDiff < 0.001) score *= 0.3;

  return Math.max(0, score);
}
```

---

**Related skills:**
- [jito-bundles.md](jito-bundles.md) — Bundle submission for atomic arb
- [mev-landscape.md](mev-landscape.md) — MEV concepts overview
- [mempool-monitoring.md](mempool-monitoring.md) — Real-time price monitoring
- [mev-risk-analysis.md](mev-risk-analysis.md) — Risk scoring
