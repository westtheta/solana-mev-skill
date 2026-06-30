---
globs:
  - "**/*.rs"
exclude:
  - "**/target/**"
---

# Rust Standards for Solana MEV Programs

These rules apply to Anchor and native Solana programs used in MEV strategies.

## General Rules

### Use Anchor by default

```rust
use anchor_lang::prelude::*;

declare_id!("...");

#[program]
pub mod mev_program {
    use super::*;
}
```

### Document all accounts

```rust
/// Instruction: [description]
#[derive(Accounts)]
pub struct ProcessMev<'info> {
    /// The searcher executing this strategy
    #[account(mut)]
    pub searcher: Signer<'info>,

    /// The token account for the input token
    #[account(mut)]
    pub token_account: Account<'info, TokenAccount>,
}
```

## MEV-Specific Patterns

### Safe CPI calls

```rust
use anchor_lang::solana_program::program::invoke;

pub fn safe_cpi_call(
    accounts: &[AccountInfo],
    instruction: &Instruction,
) -> Result<()> {
    // Always check return value
    invoke(instruction, accounts)
        .map_err(|e| error!(MevError::CpiFailed))?;
    Ok(())
}
```

### Error handling

```rust
#[error_code]
pub enum MevError {
    #[msg("CPI call failed")]
    CpiFailed,
    #[msg("Insufficient profit")]
    InsufficientProfit,
    #[msg("Slippage exceeded")]
    SlippageExceeded,
}
```

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_profit_calculation() {
        // Test profit calculation logic
    }
}
```
