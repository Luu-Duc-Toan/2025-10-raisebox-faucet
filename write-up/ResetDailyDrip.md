# Repeat claims reset `dailyDrips`

## Description

- `dailyDrips` should reset only when a new day start

- The contract incorrectly resets `dailyDrips` in the else branch when executing ETH claims for users already claiming

````Solidity
function claimFaucetTokens() public {
    //...
    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
        //...
    } else {
        dailyDrips = 0;
    }
    //...
}
```
````

## Risk

**Likelihood**:

- Any address that has claimed ETH before and waited 3 days cooldown can claim again to reset `dailyDrips`

**Impact**:

- Daily ETH distribution cap can be bypassed

- Faucet ETH balance can be drained faster than intended

- Disrupts fair distribution mechanism

## Proof of Concept

### Textual PoC

1. Claimer claims ETH for the first time.
2. After 3 days, claimer claims again and resets `dailyDrips` to 0.

### Coded PoC

[UnexpectedDailyDripsReset.t.sol](../test/UnexpectedDailyDripsReset.t.sol)

## Recommended Mitigation

Remove the incorrect reset:

```diff

function claimFaucetTokens() public {
        //...
        if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
           //...
        }
-      else {
-          dailyDrips = 0;
-      }
}
```

This ensures `dailyDrips` is only reset at day boundaries and cannot be manipulated by repeat callers.
