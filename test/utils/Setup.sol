// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {CodeConstants, HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

abstract contract TestRaffle is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    HelperConfig.NetworkConfig cfg;

    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        cfg = helperConfig.getConfig();

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: cfg.entranceFee}();
        _;
    }

    modifier intervalPassed() {
        vm.warp(block.timestamp + cfg.interval + 1); // cheat code to modify block timestamp
        vm.roll(block.number + 1); // cheat code to modify block number
        _;
    }

    modifier skipFork() {
        // in fork tests the VRF contracts can only be called by chainlink nodes
        if (block.chainid != LOCAL_CHAIN_ID) {
            vm.skip(true);
        }
        _;
    }
}
