// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title A sample Raffle Contract
 * @author Peter Berekvolgyi
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();

    /* Type declarations */

    /* State variables */
    // Chainlink VRF Variables

    // Lottery Variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /* Events */
    event EnteredRaffle(address indexed player);

    /* Functions */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {}
}
