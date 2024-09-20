// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(config.vrfCoordinatorV2_5);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.subscriptionId, config.vrfCoordinatorV2_5, config.linkToken);

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.keyHash,
            config.callbackGasLimit,
            config.entranceFee,
            config.interval,
            config.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        // broadcasting is done in addConsumer
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subscriptionId);
        return (raffle, helperConfig);
    }
}
