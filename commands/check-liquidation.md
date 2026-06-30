---
description: "Check for undercollateralized positions across Kamino, Marginfi, and Save protocols"
---

You are checking for liquidation opportunities. This command monitors lending protocols for positions with health factors below 1 and reports liquidation profitability.

## Usage

```
/check-liquidation [options] [protocols]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--protocols` | Comma-separated protocols | kamino,marginfi,save |
| `--min-profit` | Minimum profit in USD | 10 |
| `--max-positions` | Max positions to report | 20 |
| `--stream` | Stream updates in real-time | false |

## Step 1: Check Positions

```bash
echo "Checking for undercollateralized positions..."
echo ""

for each protocol in PROTOCOLS:
    positions = fetch_liquidatable_positions(protocol)

    for each position in positions:
        profit = calculate_profit(position)
        if profit > MIN_PROFIT:
            echo "  ⚠ Position: $POSITION.OWNER"
            echo "    Protocol: $PROTOCOL"
            echo "    Health Factor: $POSITION.HEALTH_FACTOR"
            echo "    Estimated Profit: $PROFIT USD"
            echo ""
```

## Step 2: Report Summary

```bash
echo "═══ Liquidation Report ═══"
echo ""
echo "Total liquidatable positions: $TOTAL"
echo "Profitable opportunities: $PROFITABLE"
echo "Estimated total profit: $TOTAL_PROFIT USD"
echo ""
echo "Commands:"
echo "  /analyze-tx-mev <signature> — Analyze a specific tx"
echo "  /simulate-bundle — Build and simulate liquidation bundle"
```
