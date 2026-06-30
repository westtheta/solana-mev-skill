# Solana MEV Strategy Skill for Claude Code

A Claude Code skill addon for Solana MEV (Maximal Extractable Value) strategy — covering Jito bundles, arbitrage detection, liquidation opportunities, sandwich protection, mempool monitoring, and MEV risk analysis.

> **Extends**: [solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill)

## Overview

This skill is an **addon** to the core Solana development skill. It adds MEV-specific capabilities while delegating program development and core patterns to solana-dev-skill.

```
┌─────────────────────────────────────────────────────────────────┐
│                     solana-mev-skill (addon)                     │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  MEV Skills                                               │  │
│  │  ├── MEV Landscape (concepts, types, opportunities)       │  │
│  │  ├── Jito Bundles (submission, tipping, searchers)        │  │
│  │  ├── Arbitrage Detection (cross-DEX, triangular)          │  │
│  │  ├── Liquidation Monitoring (Kamino, Marginfi, Save)      │  │
│  │  ├── Sandwich Protection (mechanics, user protection)     │  │
│  │  ├── Mempool Monitoring (gRPC, Jito mempool)             │  │
│  │  └── MEV Risk Analysis (TX scoring, forensics)           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼ references                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  solana-dev-skill (core)                                  │  │
│  │  ├── Frontend (framework-kit, kit-web3-interop)           │  │
│  │  ├── Programs (Anchor, Pinocchio)                         │  │
│  │  ├── Testing (LiteSVM, Mollusk, Surfpool)                 │  │
│  │  └── Security (program + client checklists)               │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## What's Included

### MEV-Specific Skills (This Addon)

| Skill | Description |
|-------|-------------|
| [mev-landscape.md](skill/mev-landscape.md) | MEV concepts, types, and Solana-specific landscape |
| [jito-bundles.md](skill/jito-bundles.md) | Jito bundle submission, tipping optimization, searcher patterns |
| [arbitrage.md](skill/arbitrage.md) | Cross-DEX and triangular arbitrage detection |
| [liquidations.md](skill/liquidations.md) | Liquidation opportunity monitoring (Kamino, Marginfi, Save) |
| [sandwich-protection.md](skill/sandwich-protection.md) | Sandwich attack mechanics and user protection |
| [mempool-monitoring.md](skill/mempool-monitoring.md) | Yellowstone gRPC, Jito mempool, slot streaming |
| [mev-risk-analysis.md](skill/mev-risk-analysis.md) | TX risk scoring, MEV forensics |
| [resources.md](skill/resources.md) | Curated MEV-focused SDKs and references |

### Core Skills (from solana-dev-skill)

| Skill | Description |
|-------|-------------|
| frontend-framework-kit.md | React hooks, wallet connection |
| kit-web3-interop.md | Kit ↔ web3.js boundary patterns |
| security.md | Security checklist (programs + clients) |
| programs-anchor.md | Anchor framework patterns |
| programs-pinocchio.md | High-performance Pinocchio |
| idl-codegen.md | IDL generation, client codegen |
| testing.md | LiteSVM, Mollusk, Surfpool |

## Installation

### Recommended: Custom Install

If you're reading this, use the **custom installer** for full control:

```bash
git clone https://github.com/solanabr/solana-mev-skill
cd solana-mev-skill
./install-custom.sh
```

The custom installer lets you:
- Choose install location (personal `~/.claude/skills/` or project `./.claude/skills/`)
- Skip core skill if you already have `solana-dev-skill`
- Choose where to place `CLAUDE.md`

### Standard Install (Automation)

For scripts, CI/CD, or quick setup with defaults:

```bash
./install.sh        # Interactive with defaults
./install.sh -y     # Non-interactive, all defaults
```

**Standard defaults:**
- Location: `~/.claude/skills/`
- Installs both `solana-dev` and `solana-mev` skills
- Copies `CLAUDE.md` to `~/.claude/`

### If You Already Have solana-dev-skill

Use `./install-custom.sh` — it detects existing installations and only installs the MEV addon.

## Default Stack (June 2026)

### MEV Bots
| Layer | Choice |
|-------|--------|
| Runtime | Node.js 22+ / TypeScript 5.x |
| SDK | @solana/kit |
| Bundles | jito-sdk |
| DEX | @jup-ag/api, @orca-so/whirlpools-sdk, @meteora-ag/dlmm |
| Streaming | yellowstone-grpc |
| RPC | Helius or Triton |

### Web Dashboards
| Layer | Choice |
|-------|--------|
| Framework | Next.js 15 (App Router) |
| SDK | @solana/kit + @solana/react-hooks |
| Charts | Recharts |
| State | Zustand + React Query |

## MEV Types Covered

| MEV Type | Profit Source | Risk Level |
|----------|--------------|------------|
| **DEX Arbitrage** | Price discrepancies across DEXes | Low |
| **Triangular Arbitrage** | Price differences within single DEX pools | Medium |
| **Liquidations** | Liquidation bonuses from protocols | Medium |
| **Jito Bundles** | Atomic MEV extracted in ordered bundles | Low |
| **Backrunning** | Following large txs that move price | Medium |
| **Sandwich Attacks** | Frontrunning + backrunning user txs | High (toxic) |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| **mev-architect** | opus | MEV strategy, architecture, opportunity assessment |
| **searcher-engineer** | sonnet | Searcher/bot implementation, bundle building |
| **mev-guide** | sonnet | Education, tutorials, concept explanations |

## Commands

| Command | Purpose |
|---------|---------|
| **/simulate-bundle** | Simulate a Jito bundle before submission |
| **/find-arb** | Scan DEXes for arbitrage opportunities |
| **/check-liquidation** | Check for undercollateralized positions |
| **/analyze-tx-mev** | Analyze a transaction for MEV risk |

## Usage Examples

### MEV Strategy
```
"Explain the MEV landscape on Solana"
"What types of MEV exist on Solana?"
"Design an MEV-aware architecture for my DEX"
```

### Jito Bundles
```
"Show me how to build and submit a Jito bundle"
"How do I optimize my Jito tips to maximize profit?"
"Create a searcher bot that monitors the Jito mempool"
```

### Arbitrage
```
"Find arbitrage opportunities between Orca and Raydium"
"Build a triangular arbitrage scanner for Jupiter"
"Calculate expected profit for a cross-DEX arb trade"
```

### Liquidations
```
"Monitor Kamino for undercollateralized positions"
"Build a liquidation bot for Marginfi"
"Calculate liquidation profitability"
```

### MEV Protection
```
"How do sandwich attacks work on Solana?"
"Protect my swap txs from MEV"
"Analyze this tx for MEV risk"
```

## Repository Structure

```
solana-mev-skill/
├── CLAUDE.md                    # Claude configuration
├── README.md                    # This file
├── install.sh                   # Standard installer
│
├── skill/                       # MEV addon skills
│   ├── SKILL.md                # Entry point
│   ├── mev-landscape.md        # MEV concepts
│   ├── jito-bundles.md         # Jito infrastructure
│   ├── arbitrage.md            # DEX arbitrage
│   ├── liquidations.md         # Liquidations
│   ├── sandwich-protection.md   # Sandwich attacks
│   ├── mempool-monitoring.md   # Mempool/gRPC
│   ├── mev-risk-analysis.md    # Risk scoring
│   └── resources.md            # References
│
├── agents/                      # Specialized agents
├── commands/                    # Workflow commands
└── rules/                       # Code rules
```

## License

MIT License — see [LICENSE](LICENSE) for details.

---

Maintained by [Superteam Brazil](https://github.com/solanabr)
