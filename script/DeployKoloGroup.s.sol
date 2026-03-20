// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {KoloGroup} from "../src/KoloGroup.sol";

contract DeployKoloGroup is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment variable
       // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcast to record transactions
        vm.startBroadcast();

        // Deploy KoloGroup contract
        KoloGroup koloGroup = new KoloGroup();
        
        // Log deployment details
       // console.log("KoloGroup deployed at:", address(koloGroup));

        vm.stopBroadcast();
    }
}