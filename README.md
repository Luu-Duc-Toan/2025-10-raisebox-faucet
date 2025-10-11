# Protocol Name

Raisebox faucet

- Starts: October 09, 2025 Noon UTC
- Ends: October 16, 2025 Noon UTC

- nSLOC: 157

[//]: # "contest-details-open"

## About the Project

About

RaiseBox Faucet is a token drip faucet that drips 1000 test tokens to users every 3 days. It also drips 0.005 sepolia eth to first time users.

The faucet tokens will be useful for testing the testnet of a future protocol that would only allow interactions using this tokens.

## Actors

There are basically 3 actors in this protocol:

## 1. Owner:

#### RESPONSIBILITIES:

- deploys contract,
- mint initial supply and any new token in future,
- can burn tokens,
- can adjust daily claim limit,
- can refill sepolia eth balance

#### LIMITATIONS:

- cannot claimfaucet tokens

## 2. Claimer:

#### RESPONSIBILITIES:

- can claim tokens by calling the claimFaucetTokens function of this contract.

#### LIMITATIONS:

- Doesn't have any owner defined rights above.

## 3. Donators:

#### RESPONSIBILITIES:

- can donate sepolia eth directly to contract

[//]: # "contest-details-close"
[//]: # "scope-open"

## Scope (contracts)

```
src/
├── RaiseBoxFaucet.sol
├── DeployRaiseBoxFaucet.s.sol

```

## Compatibilities

- Blockchains:
  - Ethereum/EVM
- Tokens:
  - SEP ETH

[//]: # "scope-close"
[//]: # "getting-started-open"

## Setup

Build:

```
git clone https://github.com/CodeHawks-Contests/2025-10-raisebox-faucet.git

forge init

forge install OpenZeppelin/openzeppelin-contracts

forge install forge-std

forge build

```

Tests:

```
Forge test

```

[//]: # "getting-started-close"
[//]: # "known-issues-open"

## Known Issues

Known Issues:

No known issues.

[//]: # "known-issues-close"
