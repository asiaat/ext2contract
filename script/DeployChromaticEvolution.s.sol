// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import { ChromaticEvolution } from "../src/ChromaticEvolution.sol";
import {console} from "forge-std/console.sol";


contract DeployChromaticEvolution is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;



    function run() external returns ( ChromaticEvolution ) {

       

        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;           
            
        } else if (block.chainid == 11155111 ){
            deployerKey = vm.envUint("SEPOLIA_PRV_KEY");          

        } else if (block.chainid == 80001 ){
            deployerKey = vm.envUint("MUMBAI_PRV_KEY");       
        
        } else {
            deployerKey = vm.envUint("GOERLI_PRV_KEY");
        }
        vm.startBroadcast(deployerKey);
        ChromaticEvolution nft = new ChromaticEvolution(
            
            "ChromaticEvolution2",
            "CHEVO2"
        );
        vm.stopBroadcast();
        return nft;
    }
}