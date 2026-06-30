---
name: solana-mev
description: Solana MEV (Maximal Extractable Value) strategy skill covering Jito bundles, arbitrage detection, liquidation opportunities, sandwich protection, mempool monitoring, and MEV risk analysis. Extends solana-dev-skill with MEV-specific patterns for building searchers, protecting users, and analyzing on-chain activity.
user-invocable: true
---

# Solana MEV Strategy Skill

> **Extends**: [solana-dev-skill](../solana-dev/SKILL.md) - Core Solana development (programs, frontend, testing, security)

## What This Skill Is For

Use this skill when the user asks for:

### MEV Strategy & Architecture
- Understanding MEV landscape on Solana (arbitrage, liquidations, sandwiches, Jito bundles)
- Designing MEV-aware architectures for protocols
- Evaluating MEV risks in a DeFi protocol design

### Jito Integration
- Building and submitting Jito bundles
- Tip optimization strategies (static, dynamic, auction-based)
- Searcher patterns for Jito block engine
- Bundle simulation and failure analysis

### Arbitrage Detection
- Cross-DEX price scanning (Jupiter, Orca, Meteora, Raydium)
- Triangular arbitrage detection
- Flash swap / flash loan arbitrage
- Statistical arbitrage with historical data

### Liquidation Opportunities
- Monitoring Kamino, Marginfi, Save for undercollateralized positions
- Liquidation profitability calculation
- Automated liquidation bots
- Health factor tracking

### Sandwich Protection
- How sandwich attacks work on Solana
- Protecting user transactions with Jito bundles
- Slippage analysis and MEV-aware routing
- Detecting sandwich attacks in transaction history

### Mempool & Monitoring
- Yellowstone gRPC for real-time slot/account streaming
- Jito mempool subscription
- Transaction lifecycle tracking
- MEV bot telemetry

### MEV Risk Analysis
- Transaction risk scoring (0-100)
- Detecting frontrunning, backrunning, sandwich attempts
- Analyzing historical txs for MEV extraction
- Building MEV dashboards

## Default Stack Decisions (Opinionated)

### 1) MEV Bots: TypeScript + Node.js
- `jito-sdk` for bundle submission
- `@solana/kit` for transaction building
- `@jup-ag/api` for Jupiter price quotes
- `@orca-so/whirlpools-sdk` for Orca pools
- `@meteora-ag/dlmm` for Meteora DLMM

### 2) Monitoring: Yellowstone gRPC
- `yellowstone-grpc` for real-time data streaming
- Jito Block Engine API for bundle submission
- Helius/Triton WebSocket for fallback

### 3) Web Dashboards: Next.js 15
- `@solana/kit` + `@solana/react-hooks`
- Recharts for MEV metrics visualization
- Zustand for state management

### 4) Program Development: Anchor
- For custom MEV-related programs
- LiteSVM for simulation
- Mollusk for CU profiling

## Operating Procedure

### 1. Classify the Task Layer

| Layer | Examples | Skill File(s) |
|-------|----------|---------------|
| MEV Landscape | Concepts, types, opportunities | [mev-landscape.md](mev-landscape.md) |
| Jito Bundles | Submission, tipping, searchers | [jito-bundles.md](jito-bundles.md) |
| Arbitrage | DEX scanning, execution | [arbitrage.md](arbitrage.md) |
| Liquidations | Position monitoring, health checks | [liquidations.md](liquidations.md) |
| Sandwich | Attack mechanics, protection | [sandwich-protection.md](sandwich-protection.md) |
| Mempool | gRPC streaming, monitoring | [mempool-monitoring.md](mempool-monitoring.md) |
| Risk Analysis | TX scoring, forensics | [mev-risk-analysis.md](mev-risk-analysis.md) |
| Program Dev | Anchor programs | solana-dev → programs-anchor.md |

### 2. Pick the Right Agent

| Task Type | Agent | Model |
|-----------|-------|-------|
| High-level MEV strategy | mev-architect | opus |
| Searcher/bot code | searcher-engineer | sonnet |
| Learning/concepts | mev-guide | sonnet |

### 3. Apply MEV-Specific Patterns

**Bundle Building:**
- Always simulate bundles before submission
- Set tips strategically (track recent winning tips)
- Handle blockhash expiry with retry logic
- Verify atomicity — all txs must land or none

**Arbitrage:**
- Check price impact before executing
- Simulate the full DEX route
- Account for priority fees + tip in profit calc
- Use Jito bundles for atomic arb execution

**Liquidations:**
- Monitor health factors via gRPC streaming
- Calculate profit = liquidation bonus - fees - tip
- Race other searchers — speed is critical
- Test on devnet first

**Sandwich Protection:**
- Route user txs through Jito bundles
- Use high slippage tolerance as a red flag
- Monitor mempool for sandwich attempts on user txs

### 4. Add Tests

- **Unit tests**: Arb detection logic, profit calculations
- **Integration tests**: Bundle simulation on devnet
- **Simulation**: Always simulate before mainnet submission
- **Two-strike rule**: If test fails twice, STOP and ask

### 5. Deliverables

When implementing changes, provide:
- Exact files changed with clear diffs
- Package dependencies (package.json)
- Build/test commands
- MEV risk considerations

---

## Progressive Disclosure (Read When Needed)

### MEV-Specific Skills (This Addon)

- [mev-landscape.md](mev-landscape.md) — MEV concepts, types, and Solana-specific landscape
- [jito-bundles.md](jito-bundles.md) — Jito bundle submission, tipping optimization, searcher patterns
- [arbitrage.md](arbitrage.md) — Cross-DEX and triangular arbitrage detection
- [liquidations.md](liquidations.md) — Liquidation opportunity monitoring (Kamino, Marginfi, Save)
- [sandwich-protection.md](sandwich-protection.md) — Sandwich attack mechanics and user protection
- [mempool-monitoring.md](mempool-monitoring.md) — Yellowstone gRPC, Jito mempool, slot streaming
- [mev-risk-analysis.md](mev-risk-analysis.md) — TX risk scoring, MEV forensics
- [resources.md](resources.md) — Curated links to SDKs and documentation

### Core Solana Dev Skills (from solana-dev-skill)

> These are provided by [solana-dev-skill](../solana-dev/SKILL.md) — install if not present

- [frontend-framework-kit.md](../solana-dev/frontend-framework-kit.md) — React hooks, wallet connection
- [programs-anchor.md](../solana-dev/programs-anchor.md) — Anchor framework patterns
- [testing.md](../solana-dev/testing.md) — LiteSVM, Mollusk, Surfpool
- [security.md](../solana-dev/security.md) — Security checklist

---

## Task Routing Guide

| User asks about... | Primary skill file(s) |
|--------------------|----------------------|
| What is MEV on Solana | mev-landscape.md |
| Types of MEV | mev-landscape.md |
| Jito bundle submission | jito-bundles.md |
| Tip optimization | jito-bundles.md |
| Searcher bot setup | jito-bundles.md, arbitrage.md |
| Find arb opportunities | arbitrage.md |
| Flash loan arbitrage | arbitrage.md |
| Liquidation bot | liquidations.md |
| Health factor tracking | liquidations.md |
| Sandwich attack explained | sandwich-protection.md |
| Protect my txs from sandwich | sandwich-protection.md |
| gRPC streaming setup | mempool-monitoring.md |
| Jito mempool subscription | mempool-monitoring.md |
| MEV risk score for a tx | mev-risk-analysis.md |
| Historical MEV analysis | mev-risk-analysis.md |
| MEV dashboard | mev-risk-analysis.md |
| Custom MEV program | solana-dev → programs-anchor.md |

---

## Commands

| Command | Description |
|---------|-------------|
| /simulate-bundle | Simulate a Jito bundle before submission |
| /find-arb | Scan DEXes for arbitrage opportunities |
| /check-liquidation | Check for undercollateralized positions |
| /analyze-tx-mev | Analyze a transaction for MEV risk |

## Agents

| Agent | Purpose |
|-------|---------|
| **mev-architect** | MEV strategy, architecture, opportunity assessment |
| **searcher-engineer** | Searcher/bot implementation, bundle building, arb execution |
| **mev-guide** | Education, tutorials, concept explanations |
