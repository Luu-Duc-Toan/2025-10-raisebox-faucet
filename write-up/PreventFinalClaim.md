# Off-by-One Error Prevents Final Claim in `claimFaucetTokens()`

## Summary

An off-by-one error in the balance check prevents users from claiming tokens when the faucet balance exactly equals `faucetDrip`, even though sufficient tokens exist for one more claim.

## Description

### Normal Behavior

- The faucet should reject claims when it has insufficient tokens for one claim.
- Users should be able to claim when the faucet has exactly enough tokens for one claim.

### Issue

The balance validation uses`<=` operator instead of `<`, incorrectly rejecting valid claims when the balance exactly matches the drip amount.

Line: 175 - 177

```solidity
if (balanceOf(address(this)) <= faucetDrip) {
    revert RaiseBoxFaucet_InsufficientContractBalance();
}
```

## Risk

### Impact

**Low**

- Users cannot claim the final `faucetDrip` from the faucet
- One potential first-time claimer loses the opportunity to receive ETH rewards
- Minimal financial impact relative to the total token supply

### Likelihood

**Medium**

- The faucet will naturally reach this state during normal operation.
- No external contract or special conditions required.

## Proof of Concept

### Textual PoC

1. Users claim tokens normally until the faucet balance decreases.
2. When `balanceOf(address(this)) == faucetDrip`, the next claim reverts.
3. The final `faucetDrip` amount of tokens remains locked in the contract.

### Coded PoC

```solidity
function testPreventFinalClaim() public {
    //Directly set balance to faucet drip amount
    //In real scenario, this would be done by multiple users claiming until the balance is low enough
    vm.store(
        raiseBoxFaucetContractAddress,
        keccak256(abi.encode(raiseBoxFaucetContractAddress, uint256(0))),
        bytes32(raiseBoxFaucet.faucetDrip())
    );

    vm.prank(makeAddr("lastUser"));
    vm.expectRevert();
    raiseBoxFaucet.claimFaucetTokens();
}
```

**PreventFinalClaim.t.sol**: https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/master/test/PreventFinalClaim.t.sol

Result:

```bash
Ran 1 test for test/PreventFinalClaim.t.sol:TestPreventFinalClaim
[PASS] testPreventFinalClaim() (gas: 45280)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.99ms (505.60µs CPU time)
```

## Recommended Mitigation

Change the balance check to use strictly less-than (`<`) instead of less-than-or-equal-to (`<=`):

```diff
- if (balanceOf(address(this)) <= faucetDrip) {
+ if (balanceOf(address(this)) < faucetDrip) {
    revert RaiseBoxFaucet_InsufficientContractBalance();
}
```

This allows users to claim when the faucet balance exactly equals `faucetDrip`, ensuring all available tokens can be distributed.
