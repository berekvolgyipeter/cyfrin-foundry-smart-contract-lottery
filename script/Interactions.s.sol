// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants, HelperConfig} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinator) public returns (uint256) {
        console2.log("Creating subscription on chainId: ", block.chainid);

        vm.startBroadcast();
        // VRFCoordinatorV2_5Mock inherits from createSubscription SubscriptionAPI
        // so it can create subscription on any network
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update the subscriptionId in HelperConfig.s.sol");

        return subId;
    }

    function createSubscriptionUsingConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory cfg = helperConfig.getConfig();

        return createSubscription(cfg.vrfCoordinator);
    }

    function run() external returns (uint256) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscription(uint256 subId, address vrfCoordinator, address linkToken) public {
        uint256 fundAmount;

        console2.log("Funding subscription:", subId);
        console2.log("Using vrfCoordinator:", vrfCoordinator);
        console2.log("On ChainID:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            fundAmount = MOCK_FUND_AMOUNT;

            vm.startBroadcast();
            // fundSubscription is written for local network
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, fundAmount);
            vm.stopBroadcast();
        } else {
            fundAmount = FUND_AMOUNT;

            vm.startBroadcast();
            // LinkToken inherits from ERC20 so it can be used to make transers in real networks
            LinkToken(linkToken).transferAndCall(vrfCoordinator, fundAmount, abi.encode(subId));
            vm.stopBroadcast();
        }

        console2.log("Fund amount in LINK WEI:", fundAmount);
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory cfg = helperConfig.getConfig();

        if (cfg.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            cfg.subscriptionId = createSub.run();
            console2.log("New subscriptionId created: ", cfg.subscriptionId, "VRF Address: ", cfg.vrfCoordinator);
        }

        fundSubscription(cfg.subscriptionId, cfg.vrfCoordinator, cfg.linkToken);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId) public {
        console2.log("Adding consumer contract:", contractToAddToVrf);
        console2.log("Using vrfCoordinator:", vrfCoordinator);
        console2.log("On ChainID:", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address contractToAddToVrf) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory cfg = helperConfig.getConfig();

        addConsumer(contractToAddToVrf, cfg.vrfCoordinator, cfg.subscriptionId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
