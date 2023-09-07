// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import { Ext2Contract } from "../src/Ext2Contract.sol";
import {console} from "forge-std/console.sol";


contract DeployExt2Contract is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;



    function run() external returns ( Ext2Contract ) {

       

        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;           
            
        } else if (block.chainid == 11155111 ){
            deployerKey = vm.envUint("SEPOLIA_PRV_KEY");          

        } else {
            deployerKey = vm.envUint("GOERLI_PRV_KEY");
        }
        vm.startBroadcast(deployerKey);
        Ext2Contract nft = new Ext2Contract(
            
            "Ext2Contr1",
            "Ext2Contr1"
        );
        vm.stopBroadcast();
        return nft;
    }
}