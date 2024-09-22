// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

abstract contract TestRaffle is Test {
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
}

contract TestRaffleInit is TestRaffle {
    function testRaffleInitialStateIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}

contract TestEnterRaffle is TestRaffle {
    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle{value: 0 ether}();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public enteredRaffle {
        assert(raffle.getNumberOfPlayers() == 1);
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: cfg.entranceFee}();
    }

    function testPlayersAreNotAllowedToEnterWhileStateIsCalculating() public enteredRaffle intervalPassed {
        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: cfg.entranceFee}();
    }
}

contract TestCheckUpKeep is TestRaffle {
    function testReturnsFalseIfItHasNoBalance() public intervalPassed {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testReturnsFalseIfRaffleIsntOpen() public enteredRaffle intervalPassed {
        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        assert(!upkeepNeeded);
    }

    function testReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: cfg.entranceFee}();

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testReturnsTrueWhenParametersGood() public enteredRaffle intervalPassed {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(upkeepNeeded);
    }
}

contract TestPerformUpKeep is TestRaffle {
    function testCanOnlyRunIfCheckUpkeepIsTrue() public enteredRaffle intervalPassed {
        raffle.performUpkeep("");
    }

    function testRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");

        vm.prank(PLAYER);
        raffle.enterRaffle{value: cfg.entranceFee}();
        currentBalance += cfg.entranceFee;
        numPlayers += 1;

        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    function testUpdatesRaffleStateAndEmitsRequestId() public enteredRaffle intervalPassed {
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs(); // gets emitted events
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }
}
