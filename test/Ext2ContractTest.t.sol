// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/Ext2Contract.sol";
import {Test, console}          from "forge-std/Test.sol";
import {StdCheats}              from "forge-std/StdCheats.sol";
import { Ext2Contract}          from "../src/Ext2Contract.sol";
import { DeployExt2Contract}    from "../script/DeployExt2Contract.s.sol";

contract Ext2ContractTest is StdCheats,Test {

    string constant NFT_NAME = "Ext2Contr1";
    string constant NFT_SYMBOL = "Ext2Contr1";
    Ext2Contract public nft;
    DeployExt2Contract public deployer;
    address public deployerAddress;
    address public constant USER = address(1);
    address public constant ALICE = address(2);

    function setUp() public {
         deployer = new DeployExt2Contract();
         nft = deployer.run();
         vm.deal(ALICE, 100 ether);
    }

    function test1_InitializedCorrectly() public view {
        assert(
            keccak256(abi.encodePacked(nft.name())) ==
                keccak256(abi.encodePacked((NFT_NAME)))
        );
        assert(
            keccak256(abi.encodePacked(nft.symbol())) ==
                keccak256(abi.encodePacked((NFT_SYMBOL)))
        );
    }

    function test2_CanMintAndHaveABalance() public {
        vm.deal(nft.owner(), 42 ether);
        vm.prank(nft.owner());
        nft.minting{value: 0.005 ether}(0);
        //nft.minting {value: 0.005 ether}(0);

        assert(nft.balanceOf(nft.owner()) == 1);
        console.log(nft.tokenURI(0));

        //cnt mint same token id
        vm.expectRevert();
        nft.minting{value: 0.005 ether}(0);

        // cant ming more than nft collection has items
        vm.expectRevert();
        nft.minting{value: 0.005 ether}(10000);
    }

}
