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
        HelperConfig.NetworkConfig memory cfg = helperConfig.getConfig();

        if (cfg.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            cfg.subscriptionId = createSubscription.createSubscription(cfg.vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(cfg.subscriptionId, cfg.vrfCoordinator, cfg.linkToken);

            helperConfig.setConfig(block.chainid, cfg);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            cfg.subscriptionId, cfg.keyHash, cfg.callbackGasLimit, cfg.entranceFee, cfg.interval, cfg.vrfCoordinator
        );
        vm.stopBroadcast();

        // broadcasting is done in addConsumer
        addConsumer.addConsumer(address(raffle), cfg.vrfCoordinator, cfg.subscriptionId);
        return (raffle, helperConfig);
    }
}
