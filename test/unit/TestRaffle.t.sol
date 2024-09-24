// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {TestRaffle} from "test/utils/Setup.sol";
import {Raffle} from "src/Raffle.sol";

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

contract TestFulfillRandomWords is TestRaffle {
    function testCanOnlyBeCalledAfterPerformUpkeep(uint256 requestId) public enteredRaffle intervalPassed skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(cfg.vrfCoordinator).fulfillRandomWords(requestId, address(raffle));
    }

    function testPicksAWinnerResetsAndSendsMoney() public enteredRaffle intervalPassed skipFork {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint160 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint160 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(i);
            hoax(player, 1 ether); // sets up a prank and a deal
            raffle.enterRaffle{value: cfg.entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs
        console2.log("requestId", uint256(requestId));

        VRFCoordinatorV2_5Mock(cfg.vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = cfg.entranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
