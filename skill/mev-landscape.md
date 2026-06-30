# Solana MEV Landscape

MEV (Maximal Extractable Value) concepts, types, and Solana-specific landscape. Understand how MEV works on Solana vs Ethereum, and identify the key MEV opportunities and risks.

---

## What Makes Solana MEV Different

Solana's architecture creates a fundamentally different MEV landscape from Ethereum:

| Feature | Ethereum | Solana |
|---------|----------|--------|
| **Block production** | 12s slots, proposer-builder separation | ~400ms slots, leader schedule |
| **Mempool** | Public tx pool (gossip) | No global mempool; Jito mempool |
| **MEV Capture** | Builders/validators/proposers | Searchers via Jito bundles |
| **Transaction ordering** | Proposer controls order | Leader controls order within slot |
| **Key MEV type** | Sandwich, Arbitrage, Liquidations | Arbitrage, Liquidations, Backrunning |

### MEV on Solana is Different Because:

1. **Leader schedule** — Block producers are known in advance (every ~2 days), making it possible to predict who will produce the next block
2. **No global public mempool** — Transactions are gossiped but there is no public mempool like Ethereum's. Jito runs a private mempool where searchers can bid for inclusion
3. **JitoSOL & Jito** — Jito is the dominant MEV infrastructure. Searchers submit bundles, validators accept the highest-bidding bundle
4. **Speed** — 400ms slots mean MEV opportunities appear and disappear faster than on Ethereum
5. **Atomic composability** — Cross-program invocation (CPI) enables complex multi-step MEV strategies in a single transaction

## MEV Types on Solana

### 1. DEX Arbitrage

Buy low on one DEX, sell high on another. The most common and lowest-risk MEV on Solana.

**Key DEXes:** Jupiter (aggregator), Orca, Raydium, Meteora, Phoenix, OpenBook

**Detection signals:**
- Price of token A on Orca ≠ price on Raydium
- After accounting for fees and slippage, profit > 0

```
Orca:  1 SOL = 100 USDC
Raydium: 1 SOL = 101 USDC
Profit: 1 USDC per SOL traded (minus fees)
```

### 2. Triangular Arbitrage

Exploit price inconsistencies across three trading pairs on the same or different DEXes.

```
SOL → USDC → BONK → SOL
If the loop returns more SOL than started with → opportunity
```

### 3. Liquidations

When a leveraged position becomes undercollateralized, a liquidator can repay the debt and claim a bonus.

**Solana protocols with public liquidation:**

| Protocol | Liquidation Bonus | Monitoring |
|----------|------------------|------------|
| **Kamino** | 5-10% | gRPC account streaming |
| **Marginfi** | 5-8% | gRPC account streaming |
| **Save (ex-Solend)** | 5-10% | gRPC account streaming |

### 4. Sandwich Attacks (Toxic MEV)

Frontrun a user's trade by buying before them (driving price up) and selling after them (at the inflated price).

**How it works on Solana:**
1. Detect a large pending swap in Jito mempool
2. Buy the same token before the user's tx
3. User's tx executes at the inflated price
4. Sell immediately after for a profit

**WARNING:** Sandwich attacks damage the ecosystem. The knowledge is included for defensive purposes — protecting users from being sandwiched, not to perform attacks.

### 5. Backrunning

Execute a trade immediately after a target transaction that moves the price.

**Common targets:**
- Large swaps on Orca/Raydium
- Protocol mints (new token pools)
- NFT mints and market trades

### 6. Jito Bundle MEV

Multiple transactions bundled atomically, submitted to Jito validators.

**Bundle types:**
- **Atomic arb:** Buy tx + sell tx in one bundle (no one can insert between)
- **Searcher bundle:** Backrun a user's tx with your own
- **Protection bundle:** User wraps tx to prevent sandwiching

## MEV Participant Roles

```
User                  Submits transactions to the network
  │
  ▼
Searcher              Detects MEV opportunities, builds bundles
  │
  ▼
Jito Mempool          Private tx pool where searchers find opportunities
  │
  ▼
Jito Block Engine     Receives bundles, selects best ones (highest tip)
  │
  ▼
Validator             Includes bundles in the block, earns tips
```

## MEV Opportunity Matrix

| Opportunity | Difficulty | Capital Needed | Risk | Typical Profit |
|-------------|-----------|---------------|------|----------------|
| CEX-DEX arb | High | High | Medium | High |
| Cross-DEX arb | Low | Low | Low | Low |
| Triangular arb | Medium | Low | Low | Low-Medium |
| Liquidations | High | Medium | Low | Medium |
| Backrunning | Medium | Low | Low | Low-Medium |

## Key Infrastructure

| Service | Purpose | Cost |
|---------|---------|------|
| **Jito Block Engine** | Bundle submission & tipping | Pay per bundle (tips) |
| **Yellowstone gRPC** | Real-time slot/account/tx streaming | RPC cost |
| **Helius/Triton** | RPC + Geyser access | Pay per plan |
| **Jupiter API** | Price quotes & routing | Free |
| **DEX SDKs** | Pool data, swaps | Free |

## MEV in Solana DeFi Protocols

### Jupiter
- Jupiter routing can be MEV-aware (Jupiter uses Jito bundles for protection)
- Jupiter offers "Dynamic Slippage" based on MEV conditions

### Orca Whirlpools
- Concentrated liquidity means price impact is higher → more arb opportunities
- Whirlpool swaps can be sandwiched if not protected

### Kamino / Marginfi / Save
- Lending protocols with public liquidation events
- Health factors can be tracked via account subscription

## Risk Classification

| Risk | Description |
|------|-------------|
| **Low (Green)** | Cross-DEX arbitrage with proper simulation |
| **Medium (Yellow)** | Liquidations, backrunning — competition is high |
| **High (Red)** | Sandwiches, frontrunning — toxic MEV, reputational damage |
| **Critical** | MEV strategies that reorg or exploit protocol mechanics |

## Defensive MEV

Not all MEV is extractive. Defensive MEV protects users:

- **Jito bundles for swaps** — protects users from being sandwiched
- **MEV-aware routing** — Jupiter routes through protected paths
- **Flash auctions** — users can sell MEV rights to searchers

---

**Related skills:**
- [jito-bundles.md](jito-bundles.md) — Bundle submission and tipping
- [arbitrage.md](arbitrage.md) — DEX arbitrage detection
- [liquidations.md](liquidations.md) — Liquidation opportunities
- [sandwich-protection.md](sandwich-protection.md) — Sandwich mechanics and protection
- [mempool-monitoring.md](mempool-monitoring.md) — Monitoring infrastructure
- [mev-risk-analysis.md](mev-risk-analysis.md) — Risk scoring
