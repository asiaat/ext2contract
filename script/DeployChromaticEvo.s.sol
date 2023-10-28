// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import { ChromaticEvo } from "../src/ChromaticEvo.sol";
import {console} from "forge-std/console.sol";


contract DeployChromaticEvo is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;



    function run() external returns ( ChromaticEvo ) {

       

        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;           
            
        } else if (block.chainid == 11155111 ){
            deployerKey = vm.envUint("SEPOLIA_PRV_KEY");          

        } else if (block.chainid == 80001 ){
            deployerKey = vm.envUint("MUMBAI_PRV_KEY");       
        
        }  else if (block.chainid == 137 ){
            deployerKey = vm.envUint("POLYGON_PRV_KEY");       
        
        }
        else {
            deployerKey = vm.envUint("GOERLI_PRV_KEY");
        }
        vm.startBroadcast(deployerKey);
        ChromaticEvo nft = new ChromaticEvo(
            
            "ChromaticEvo",
            "CHEV1"
        );
        vm.stopBroadcast();
        return nft;
    }
}