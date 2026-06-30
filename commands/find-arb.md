---
description: "Scan DEXes for arbitrage opportunities across Orca, Raydium, Meteora, and Jupiter"
---

You are scanning DEXes for arbitrage opportunities. This command checks price differences across multiple Solana DEXes and reports profitable arbitrage opportunities.

## Usage

```
/find-arb [options] <token-mint> [amount]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--amount` | Trade amount in SOL | 10 |
| `--min-profit` | Minimum profit in SOL | 0.01 |
| `--dexes` | Comma-separated DEX list | orca,raydium,meteora |
| `--jupiter` | Include Jupiter routing | true |

## Step 1: Fetch Prices

```bash
echo "Fetching prices from DEXes..."
echo "  Token: $TOKEN"
echo "  Amount: $AMOUNT SOL"
echo ""

# Fetch from each DEX
echo "  Orca:      $ORCA_PRICE"
echo "  Raydium:   $RAYDIUM_PRICE"
echo "  Meteora:   $METEORA_PRICE"
```

## Step 2: Find Opportunities

```bash
echo ""
echo "═══ Arbitrage Opportunities ═══"
echo ""

# Compare each pair
for each pair (buy-dex, sell-dex):
    profit = sell_price - buy_price
    after_fees = profit - buy_fee - sell_fee

    if after_fees > MIN_PROFIT:
        echo "  ✓ BUY on $BUY_DEX @ $BUY_PRICE"
        echo "    SELL on $SELL_DEX @ $SELL_PRICE"
        echo "    Profit: $AFTER_FEES SOL (after fees)"
        echo ""
```

## Step 3: Execute (Optional)

```bash
# To execute, use /simulate-bundle with the built bundle
echo "To execute:"
echo "  ./simulate-bundle --pair $BUY_DEX/$SELL_DEX --token $TOKEN --amount $AMOUNT"
```
