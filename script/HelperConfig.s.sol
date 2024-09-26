// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    // VRF mock values
    uint96 public constant MOCK_BASE_FEE = 0.0025 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant MOCK_FUND_AMOUNT = 100 ether;

    address public constant ANVIL_PUBLIC_KEY_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

abstract contract PersonalDataScript is Script {
    address immutable PUBLIC_KEY_DEPLOYER_ACCOUNT = vm.envAddress("PUBLIC_KEY_DEPLOYER_ACCOUNT");
    uint256 immutable SUBSCRIPTION_ID_MAINNET = vm.envUint("SUBSCRIPTION_ID_MAINNET");
    uint256 immutable SUBSCRIPTION_ID_SEPOLIA = vm.envUint("SUBSCRIPTION_ID_SEPOLIA");
}

contract HelperConfig is CodeConstants, PersonalDataScript {
    /* ---------- Errors ---------- */
    error HelperConfig__InvalidChainId();

    /* ---------- Type declarations ---------- */
    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        address linkToken;
        address account;
    }

    /* ---------- State variables ---------- */
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /* ---------- Functions ---------- */
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        // Note: We skip doing the local config
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory mainnetNetworkConfig) {
        // https://docs.chain.link/vrf/v2-5/supported-networks#ethereum-mainnet
        mainnetNetworkConfig = NetworkConfig({
            subscriptionId: SUBSCRIPTION_ID_MAINNET, // If left as 0, our scripts will create one!
            keyHash: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
            callbackGasLimit: 500_000,
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: PUBLIC_KEY_DEPLOYER_ACCOUNT
        });
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        // https://docs.chain.link/vrf/v2-5/supported-networks#sepolia-testnet
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: SUBSCRIPTION_ID_SEPOLIA, // If left as 0, our scripts will create one!
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500_000,
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: PUBLIC_KEY_DEPLOYER_ACCOUNT
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");

        vm.startBroadcast(ANVIL_PUBLIC_KEY_0);
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5Mock).fundSubscription(subscriptionId, MOCK_FUND_AMOUNT);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: subscriptionId, // If left as 0, our scripts will create one!
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            callbackGasLimit: 500_000,
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            linkToken: address(linkToken),
            account: ANVIL_PUBLIC_KEY_0
        });

        return localNetworkConfig;
    }
}
