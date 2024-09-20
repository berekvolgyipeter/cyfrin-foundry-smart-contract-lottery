// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinatorV2_5) public returns (uint256) {
        console2.log("Creating subscription on chainId: ", block.chainid);

        vm.startBroadcast();
        // TODO: why are we using mock here?
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();

        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update the subscriptionId in HelperConfig.s.sol");

        return subId;
    }

    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        return createSubscription(config.vrfCoordinatorV2_5);
    }

    function run() external returns (uint256) {
        return createSubscriptionUsingConfig();
    }
}
