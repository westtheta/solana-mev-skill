# Solana MEV Resources

Curated links to SDKs, documentation, tools, and references for MEV development on Solana.

---

## Official Documentation

| Resource | URL |
|----------|-----|
| Jito Docs | https://docs.jito.wtf |
| Jito Block Engine API | https://docs.jito.wtf/api/block-engine |
| Jito Mempool | https://docs.jito.wtf/mempool |
| Yellowstone gRPC | https://github.com/rpcpool/yellowstone-grpc |
| Solana RPC Docs | https://docs.solana.com/api/http |

## SDKs & Libraries

### Jito

| Package | Description | Docs |
|---------|-------------|------|
| `jito-sdk` | Jito bundle submission and mempool | npm: `jito-sdk` |
| `jito-ts` | TypeScript types for Jito | npm: `jito-ts` |
| `yellowstone-grpc` | Yellowstone gRPC client | npm: `yellowstone-grpc` |

### DEX SDKs

| Package | DEX | Docs |
|---------|-----|------|
| `@jup-ag/api` | Jupiter aggregator | https://docs.jup.ag |
| `@orca-so/whirlpools-sdk` | Orca Whirlpools | https://docs.orca.so |
| `@meteora-ag/dlmm` | Meteora DLMM | https://docs.meteora.ag |
| `@raydium-io/raydium-sdk` | Raydium | https://docs.raydium.io |
| `@openbook-dex/openbook` | OpenBook (SRM v2) | https://docs.openbook.com |

### Core Solana

| Package | Description |
|---------|-------------|
| `@solana/kit` | Modern Solana SDK |
| `@solana/web3.js` | Legacy web3.js |
| `@solana/react-hooks` | React hooks (framework-kit) |

## MEV Tools & Services

| Tool | Description | URL |
|------|-------------|-----|
| **Helius** | RPC + Geyser + DAS API | https://helius.xyz |
| **Triton** | RPC + gRPC infrastructure | https://triton.one |
| **Jito Block Explorer** | View bundles and tips | https://explorer.jito.wtf |
| **Solscan** | Transaction explorer | https://solscan.io |
| **SolanaFM** | Block explorer | https://solana.fm |
| **DexScreener** | DEX price tracking | https://dexscreener.com/solana |

## Relevant Programs

### DEX Programs

| Protocol | Program ID |
|----------|------------|
| Jupiter | `JUP6LkbZbjS1jKKwapdHX74TafTf7kFfAZBmFQ6J8xg` |
| Orca Whirlpools | `whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc` |
| Raydium CLMM | `CAMMCzo5YLJw8QkntKvZVeK4x8GpGCKTHm3BWBjFkA6k` |
| Meteora DLMM | `LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo` |
| Meteora DAMM | `Eo7WjKqfcJQJaxWCr6fa3CbSYgBVX8EXc2swLgN7eJV` |
| Phoenix | `PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY` |
| OpenBook | `srmqPvymJeFKQ4zGQed1GFppgkRHL9kaELCbyksJtPX` |

### Lending Programs

| Protocol | Program ID |
|----------|------------|
| Kamino | `KLend2g3cD87oWvUZLDpGrCBqHczTfCaKZnAQkF8Zc` |
| Marginfi | `MFv2hWfMjAMSCGJa1FSoNzQKTRTJzFfVKXvBsP4ab4z` |
| Save (Solend) | `So1enWd3iuSDpZ4Nhz7MvBGTWKMjLxJg8UkCkTDMjK6` |

### Jito Programs

| Program | Address |
|---------|---------|
| Jito Tip Program | `TiPiLA4jD1z8j1eSpostzthkKGdwRuMMtL8ofNfGPsd` |
| Jito Tip Distribution | `4R3gSG8NpB6wA3Hc5wRA1RcbKUmJFBQw8q48ZpK9frY` |

## Reference Implementations

| Repository | Description |
|------------|-------------|
| jito-labs/searcher-examples | Official Jito searcher examples |
| jito-labs/mev-bot-rust | MEV bot in Rust |
| jup-ag/jupiter-bot | Jupiter swap bot |
| orca-so/whirlpools-sdk | Orca SDK + examples |

## MEV Metrics & Data

| Resource | Description |
|----------|-------------|
| Jito MEV Dashboard | https://metrics.jito.wtf |
| Solana MEV Tracker | Community dashboards |
| Dune Analytics | MEV queries (Solana datasets) |

---

**Last updated:** June 2026
