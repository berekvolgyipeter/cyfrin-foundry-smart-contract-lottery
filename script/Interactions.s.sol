// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants, HelperConfig} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinatorV2_5) public returns (uint256) {
        console2.log("Creating subscription on chainId: ", block.chainid);

        vm.startBroadcast();
        // VRFCoordinatorV2_5Mock inherits from createSubscription SubscriptionAPI
        // so it can create subscription on any network
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

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscription(uint256 subId, address vrfCoordinatorV2_5, address linkToken) public {
        console2.log("Funding subscription:", subId);
        console2.log("Fund amount in LINK WEI:", FUND_AMOUNT);
        console2.log("Using vrfCoordinator:", vrfCoordinatorV2_5);
        console2.log("On ChainID:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            // fundSubscription is written for local network
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            // LinkToken inherits from ERC20 so it can be used to make transers in real networks
            LinkToken(linkToken).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            config.subscriptionId = createSub.run();
            console2.log(
                "New subscriptionId created: ", config.subscriptionId, "VRF Address: ", config.vrfCoordinatorV2_5
            );
        }

        fundSubscription(config.subscriptionId, config.vrfCoordinatorV2_5, config.linkToken);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
