// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {TestRaffle} from "test/utils/Setup.sol";
import {EnterRaffle} from "script/Interactions.s.sol";
import {Raffle} from "src/Raffle.sol";

contract InteractionsTest is TestRaffle {
    function testInteractionPicksAWinnerResetsAndSendsMoney() public skipFork {
        address expectedWinner = address(2);

        // Arrange
        EnterRaffle enterRaffle = new EnterRaffle();
        uint256 additionalEntrances = 10;
        uint160 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint160 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(i);
            vm.deal(player, 1 ether);
            enterRaffle.enterRaffle(address(raffle), player);
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.warp(block.timestamp + cfg.interval + 1);
        vm.roll(block.number + 1);

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
        uint256 prize = cfg.entranceFee * additionalEntrances;

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
