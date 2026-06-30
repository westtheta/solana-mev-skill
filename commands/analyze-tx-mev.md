---
description: "Analyze a Solana transaction for MEV risk, sandwich detection, and MEV extraction measurement"
---

You are analyzing a transaction for MEV risk. This command examines a Solana transaction signature and provides a detailed MEV risk assessment.

## Usage

```
/analyze-tx-mev <signature>
```

## Step 1: Fetch Transaction

```bash
echo "Fetching transaction $SIGNATURE..."
echo ""

TX=$(solana confirm -v $SIGNATURE 2>&1)

# Check basic info
echo "  Slot: $SLOT"
echo "  Success: $SUCCESS"
echo "  Fee: $FEE SOL"
```

## Step 2: MEV Risk Analysis

```bash
echo ""
echo "═══ MEV Risk Analysis ═══"
echo ""

# Analyze swap patterns
echo "  Swap type: $SWAP_TYPE"
echo "  Amount: $AMOUNT"
echo "  Slippage: $SLIPPAGE%"

# Risk scoring
echo "  Overall risk score: $RISK_SCORE/100"
echo ""
echo "  Risk factors:"
echo "    • Large amount: $LARGE_AMOUNT_RISK"
echo "    • Low liquidity: $LOW_LIQUIDITY_RISK"
echo "    • High slippage: $HIGH_SLIPPAGE_RISK"
echo "    • Unprotected: $UNPROTECTED_RISK"
```

## Step 3: Sandwich Detection

```bash
echo ""
echo "═══ Sandwich Detection ═══"
echo ""

# Check transactions before and after in the block
echo "  Frontrun detected: $FRONTRUN"
echo "  Backrun detected: $BACKRUN"
echo "  Estimated loss: $LOSS SOL"

if [ "$SANDWICHED" = "true" ]; then
    echo ""
    echo "  ⚠ This transaction WAS sandwiched!"
    echo "  Attacker: $ATTACKER"
    echo "  Profit: $ATTACKER_PROFIT SOL"
    echo ""
    echo "  Recommendation: Use Jito bundle protection for future swaps"
fi
```

## Step 4: Recommendations

```bash
echo ""
echo "═══ Recommendations ═══"
echo ""
echo "  Risk Level: $RISK_LEVEL"
echo "  $RECOMMENDATION"
echo ""
echo "  For future transactions, consider:"
echo "    • Using Jito bundle submission"
echo "    • Setting lower slippage tolerance"
echo "    • Splitting large swaps into smaller amounts"
```
