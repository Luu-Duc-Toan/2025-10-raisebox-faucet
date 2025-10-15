# Owner Can Claim Token Via `burnFaucetTokens()`

## Summary

The `burnFaucetTokens()` function allows the contract owner to claim all faucet tokens by transferring the entire balance to owner and burn only amount that can be less than faucet balance

## Description

### Normal Behavior

- The owner should not be able to claim faucet tokens

### Issue

The `burnFaucetTokens()` function first transfers the entire faucet token balance to the owner, then burns only the specified `amountToBurn` from the owner's balance. This means the owner receives `balanceOf(faucet) - amountToBurn` tokens.

Line: 132

```solidity
function burnFaucetTokens(uint256 amountToBurn) public onlyOwner {
    require(amountToBurn <= balanceOf(address(this)), "Faucet Token Balance: Insufficient");

    // transfer faucet balance to owner first before burning
    // ensures owner has a balance before _burn (owner only function) can be called successfully
    _transfer(address(this), msg.sender, balanceOf(address(this)));

    _burn(msg.sender, amountToBurn);
}
```

## Risk

### Impact

**High**

- Owner can bypass faucet limitations and claim all tokens.
- Faucet can be drained in a single transaction.
- Remaining ETH in the contract become locked.

### Likelihood

**High**

- Exploitable in one transaction by the owner.
- No external contract or special conditions required.

## Proof of Concept

### Textual PoC

1. Owner calls `burnFaucetTokens(0)`.
2. Faucet transfers all tokens to the owner.
3. Zero tokens are burned.
4. Owner receives the entire faucet balance.

### Coded PoC

```solidity
function testOwnerCanClaimTokenViaBurnFunction() public {
    uint256 faucetInitialBalance = raiseBoxFaucet.balanceOf(
        raiseBoxFaucetContractAddress
    );

    vm.prank(owner);
    raiseBoxFaucet.burnFaucetTokens(0);

    vm.assertEq(
        IERC20(raiseBoxFaucetContractAddress).balanceOf(owner),
        faucetInitialBalance
    );
    vm.assertEq(
        IERC20(raiseBoxFaucetContractAddress).balanceOf(
            raiseBoxFaucetContractAddress
        ),
        0
    );
}
```

**OwnerCanClaimTokenViaBurnFunction.t.sol**: https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/main/test/OwnerCanClaimTokenViaBurnFunction.t.sol

Results:

```bash
Ran 1 test for test/OwnerCanClaimTokenViaBurnFunction.t.sol:TestOwnerCanClaimTokenViaBurnFunction
[PASS] testOwnerCanClaimTokenViaBurnFunction() (gas: 52493)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.68ms (218.30µs CPU time)
```

## Recommended Mitigation

Replace the transfer-and-burn logic with a direct burn from the faucet's balance:

```diff
function burnFaucetTokens(uint256 amountToBurn) public onlyOwner {
    require(amountToBurn <= balanceOf(address(this)), "Faucet Token Balance: Insufficient");

-    // transfer faucet balance to owner first before burning
-    // ensures owner has a balance before _burn (owner only function) can be called successfully
-    _transfer(address(this), msg.sender, balanceOf(address(this)));
-    _burn(msg.sender, amountToBurn);
+    _burn(address(this), amountToBurn);
}
```
