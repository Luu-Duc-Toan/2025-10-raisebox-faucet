# Relative Time Reset

## Summary

The `claimFaucetTokens()` function uses flawed daily reset logic, which causes the daily counter to not reset properly when claims occur late in the day.

## Description

### Normal Behavior

- Daily claim counter should reset at consistent day boundaries (e.g., every 24 hours at midnight)

### Issue

The contract uses relative time calculation instead of absolute day boundaries:

Line: 220-223

```solidity
function claimFaucetTokens() public {
    //...
    if (block.timestamp > lastFaucetDripDay + 1 days) {
        lastFaucetDripDay = block.timestamp;
        dailyClaimCount = 0;
    }
    //...
}
```

This creates inconsistent daily windows that don't align with actual days and prevents legitimate users from claiming

## Risk

### Impact

**Medium**

- Daily limits don't align with actual day boundaries
- Users cannot predict when the faucet becomes available again
- Problem compounds when multiple late-day claims occur

### Likelihood

**High**

- Happens whenever claims occur late in the day
- No malicious action required, just normal usage

## Proof of Concept

### Textual PoC

1. Daily limit is reached with the last claim at 23:00 on Day 1
2. `lastFaucetDripDay` is set to Day 1 at 23:00
3. Users attempt to claim at 01:00 on Day 2
4. Reset condition `01:00_Day2 > 23:00_Day1 + 24h` evaluates to false
5. Claims remain blocked until 23:00 on Day 2, creating a ~23-hour delay

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

function testRelativeTimeReset() public {
    // Reach limit at late night (23:00 PM)
    vm.warp(block.timestamp + 23 hours);
    claimUntilLimit();

    // Revert at early next day (1:00 AM)
    vm.warp(block.timestamp + 2 hours);

    address newUser = makeAddr("newUser");
    vm.prank(newUser);
    vm.expectRevert(
        RaiseBoxFaucet.RaiseBoxFaucet_DailyClaimLimitReached.selector
    );
    raiseBoxFaucet.claimFaucetTokens();
}
```

**RelativeTimeReset.t.sol**: https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/master/test/RelativeTimeReset.t.sol

Result:

```bash
Ran 1 test for test/RelativeTimeReset.t.sol:TestRelativeTimeReset
[PASS] testRelativeTimeReset() (gas: 11788188)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 22.16ms (19.72ms CPU time)
```

## Recommended Mitigation

**Use day boundary calculation instead of relative timing**:

```diff
function claimFaucetTokens() public {
    //...
-   if (block.timestamp > lastFaucetDripDay + 1 days) {
-       lastFaucetDripDay = block.timestamp;
+   uint256 currentDay = block.timestamp / 1 days;
+   if (currentDay > lastFaucetDripDay) {
+       lastFaucetDripDay = currentDay;
        dailyClaimCount = 0;
    }
    //...
}
```
