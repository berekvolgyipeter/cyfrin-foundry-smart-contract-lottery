// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 raffleEntranceFee;
    uint256 automationUpdateInterval;
    address vrfCoordinatorV2_5;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        raffleEntranceFee = config.raffleEntranceFee;
        automationUpdateInterval = config.automationUpdateInterval;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
    }

    function testRaffleInitialStateIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
