---
description: "Simulate a Jito bundle before submission to verify it will succeed on-chain"
---

You are simulating a Jito bundle. This command takes a bundle definition and simulates it against a local or remote Solana environment to verify the bundle will land successfully.

## Usage

```
/simulate-bundle [options] <bundle-definition>
```

## Overview

Simulation is the most critical step before submitting a Jito bundle. 90% of bundle failures can be caught in simulation.

## Step 1: Parse Bundle Definition

The bundle definition should include:
- Array of transactions (base64-encoded)
- Expected tip amount
- Target slot (optional)

## Step 2: Simulate

```bash
echo "Simulating bundle..."

# Run simulation against RPC
SIM_RESULT=$(npx jito-simulate --rpc $RPC_URL --bundle "$BUNDLE_DEFINITION")

# Check result
echo "Simulation result: $SIM_RESULT"
```

## Step 3: Review Results

```bash
echo ""
echo "═══ Bundle Simulation Report ═══"
echo ""
echo "Status: $STATUS"
echo "CU consumed: $CU_USED"
echo "Logs:"
echo "$LOGS"
echo ""
echo "Recommendation:"
echo "  All pass → Submit to Jito Block Engine"
echo "  Failures → Debug failing transactions"
echo "  Warnings → Consider adjusting tip or parameters"
```
