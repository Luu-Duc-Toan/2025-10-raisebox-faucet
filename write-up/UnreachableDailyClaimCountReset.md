# Unreachable `dailyClaimCount` Reset

## Summary

The `claimFaucetTokens()` function contains unreachable reset logic where the daily counter reset code is positioned after an early revert condition, making it impossible to reset the daily claim counter once the limit is reached.

## Description

### Normal Behavior

- Users can claim tokens until `dailyClaimCount` reaches `dailyClaimLimit`
- After 24 hours, `dailyClaimCount` should reset to 0 to allow new claims

### Issue

The contract has a critical ordering issue in the claim function:

Line: 179 - 181, 220-223

```solidity
function claimFaucetTokens() public {
    //...
    if (dailyClaimCount >= dailyClaimLimit) {
        revert RaiseBoxFaucet_DailyClaimLimitReached();
    }
    //...
    if (block.timestamp > lastFaucetDripDay + 1 days) {
        lastFaucetDripDay = block.timestamp;
        dailyClaimCount = 0;
    }
    dailyClaimCount++;
}
```

**The vulnerability exists because:**

- Reset logic is positioned after the limit check
- Once `dailyClaimCount >= dailyClaimLimit`, the function always reverts before reaching reset logic
- The counter becomes permanently stuck at the limit value

## Risk

### Impact

**High**

- Faucet becomes completely unusable after reaching daily limit
- Reset mechanism exists but becomes unreachable once limit is reached
- All tokens and ETH become permanently locked in the contract
- Owner can temporarily restore functionality by increasing `dailyClaimLimit`, but this doesn't fix the underlying issue

### Likelihood

**High**

- Happens automatically when daily limit is reached through normal usage
- Attackers can deliberately trigger this vulnerability using DDoS techniques to reach the limit faster
- No external dependencies or special conditions required

## Proof of Concept

### Textual PoC

1. Users claim tokens normally until reaching `dailyClaimLimit` (e.g., 100 claims)
2. The next day, claimers cannot claim because `dailyClaimCount >= dailyClaimLimit` still reverts the transaction

### Coded PoC

```solidity
function claimUntilLimit() internal {
    for (uint256 i = 0; i < raiseBoxFaucet.dailyClaimLimit(); i++) {
        string memory userName = string.concat("user", vm.toString(i));
        address user = makeAddr(userName);

        vm.prank(user);
        raiseBoxFaucet.claimFaucetTokens();
    }
}

function testUnreachableResetDailyClaimCount() public {
    claimUntilLimit();

    //The next day claims should be possible, but they are not due to unreachable reset logic
    address newUser = makeAddr("newUser");
    vm.warp(block.timestamp + 25 hours);
    vm.expectRevert(
        RaiseBoxFaucet.RaiseBoxFaucet_DailyClaimLimitReached.selector
    );
    vm.prank(newUser);
    raiseBoxFaucet.claimFaucetTokens();
}
```

**UnreachableDailyClaimCountReset.t.sol**: https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/master/test/UnreachableDailyClaimCountReset.t.sol

**Result**:

```bash
Ran 1 test for test/UnreachableDailyClaimCountReset.t.sol:TestUnreachableDailyClaimCountReset
[PASS] testUnreachableDailyClaimCountReset() (gas: 11787524)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 15.43ms (14.64ms CPU time)
```

## Recommended Mitigation

**Move reset logic before the limit check**:

```diff
function claimFaucetTokens() public {
    //...
+   if (block.timestamp > lastFaucetDripDay + 1 days) {
+       lastFaucetDripDay = block.timestamp;
+       dailyClaimCount = 0;
+   }
    if (dailyClaimCount >= dailyClaimLimit) {
        revert RaiseBoxFaucet_DailyClaimLimitReached();
    }
    //...
-   if (block.timestamp > lastFaucetDripDay + 1 days) {
-       lastFaucetDripDay = block.timestamp;
-       dailyClaimCount = 0;
-   }
    dailyClaimCount++;
}
```
