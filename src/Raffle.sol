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

    /* Type declarations */

    /* State variables */
    // Chainlink VRF Variables

    // Lottery Variables
    uint256 private immutable i_entranceFee;

    /* Events */

    /* Functions */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}
}
