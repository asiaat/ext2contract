// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Ext2Contract is ERC721Base{

    mapping(uint256 => string)      private s_tokenIdToUri;
    mapping(uint256 => DynamicData) private tokenData;

    struct  DynamicData {
        address owner;
        uint256 status;
        uint256 mintingTime;
        uint256 durationMs;
    }

        string[] svgData = [
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'0%' y1='100%' x2='0%' y2='20%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='1700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; green; black' ",
            "'0%' y1='100%' x2='0%' y2='0%'><stop offset='25%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='35%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='15%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'40%' y1='0%' x2='30%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='180%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='10%' x2='50%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'60%' y1='10%' x2='5%' y2='60%'><stop offset='11%' stop-color='black'><animate attributeName='stop-color' values='red; green; white; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='110%' stop-color='red'><animate attributeName='stop-color' values='black; red; gray; yellow; navy; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; blue; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='105%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'47%' y1='130%' x2='16%' y2='66%'><stop offset='97%' stop-color='green'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black' dur='9700ms' begin='5s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'147%' y1='130%' x2='116%' y2='19%'><stop offset='97%' stop-color='white'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black; white' dur='8700ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='2%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'10%' y1='56%' x2='30%' y2='0%'><stop offset='55%' stop-color='white'><animate attributeName='stop-color' values='white; yellow; blue; gray; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='black'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='30%' x2='60%' y2='30%'><stop offset='5%' stop-color='yellow'><animate attributeName='stop-color' values='red; green; blue; gray; black; blue; yellow' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='72%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='75%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='5%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='10%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='14%' x2='10%' y2='10%'><stop offset='55%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='30%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'100%' y1='19%' x2='10%' y2='10%'><stop offset='59%' stop-color='red'><animate attributeName='stop-color' values='red;  white; black' dur='5000ms' begin='7s' repeatCount='indefinite' /></stop><stop offset='3%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'60%' y1='190%' x2='10%' y2='70%'><stop offset='90%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='24%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'0%' y1='100%' x2='0%' y2='20%'><stop offset='55%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='1700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; green; black' ",
            "'0%' y1='100%' x2='0%' y2='0%'><stop offset='25%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='35%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='15%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'40%' y1='0%' x2='30%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray;black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='180%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='10%' x2='50%' y2='0%'><stop offset='5%' stop-color='black'><animate attributeName='stop-color' values='red; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'60%' y1='10%' x2='5%' y2='60%'><stop offset='11%' stop-color='black'><animate attributeName='stop-color' values='red; green; white; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='110%' stop-color='red'><animate attributeName='stop-color' values='black; red; gray; yellow; navy; green; black' ",
            "'10%' y1='70%' x2='60%' y2='30%'><stop offset='50%' stop-color='black'><animate attributeName='stop-color' values='red; blue; green; blue; gray; black' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='105%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'47%' y1='130%' x2='16%' y2='66%'><stop offset='97%' stop-color='green'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black' dur='9700ms' begin='5s' repeatCount='indefinite' /></stop><stop offset='20%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'147%' y1='130%' x2='116%' y2='19%'><stop offset='97%' stop-color='white'><animate attributeName='stop-color' values='red; blue; white; green; blue; gray; black; white' dur='8700ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='2%' stop-color='black'><animate attributeName='stop-color' values='black; red; yellow;  green; blue; black' ",
            "'10%' y1='56%' x2='30%' y2='0%'><stop offset='55%' stop-color='white'><animate attributeName='stop-color' values='white; yellow; blue; gray; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='black'><animate attributeName='stop-color' values='black; red; green; black' ",
            "'10%' y1='30%' x2='60%' y2='30%'><stop offset='5%' stop-color='yellow'><animate attributeName='stop-color' values='red; green; blue; gray; black; blue; yellow' dur='3700ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='72%' stop-color='red'><animate attributeName='stop-color' values='black; red; yellow; brown; green; blue; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='75%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='120%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='110%' x2='0%' y2='0%'><stop offset='5%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='10%' stop-color='green'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'0%' y1='14%' x2='10%' y2='10%'><stop offset='55%' stop-color='red'><animate attributeName='stop-color' values='red; navy; white; green; blue; gray;black' dur='5000ms' begin='0s' repeatCount='indefinite' /></stop><stop offset='30%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'100%' y1='19%' x2='10%' y2='10%'><stop offset='59%' stop-color='red'><animate attributeName='stop-color' values='red;  white; black' dur='5000ms' begin='7s' repeatCount='indefinite' /></stop><stop offset='3%' stop-color='white'><animate attributeName='stop-color' values='white; black; red; green; black' ",
            "'60%' y1='190%' x2='10%' y2='70%'><stop offset='90%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='24%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'60%' y1='170%' x2='10%' y2='70%'><stop offset='80%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'60%' y1='70%' x2='10%' y2='0%'><stop offset='70%' stop-color='red'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='2s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'160%' y1='170%' x2='10%' y2='70%'><stop offset='70%' stop-color='black'><animate attributeName='stop-color' values='red;  #ff80bf;  #c61aff;  #3d0099;  #00aaff; black' dur='5000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='124%' stop-color='white'><animate attributeName='stop-color' values='white; #c61aff;  #3d0099; red;' ",
            "'10%' y1='210%' x2='10%' y2='70%'><stop offset='75%' stop-color='#3d0099'><animate attributeName='stop-color' values='#d98079;  #ff80bf;  ##7ad62f;  #3d0099; #66ba72  #00aaff; #5faee3 black' dur='8000ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='100%' stop-color='white'><animate attributeName='stop-color' values='white; ##7ad62f;  #3d0099; #66ba72;' ",
            "'23%' y1='0%' x2='52%' y2='0%'><stop offset='110%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='150%' stop-color='#ba2952'><animate attributeName='stop-color' values='#7b8e9c; #baa429; #8599d4; #ba2952; ' ",
            "'123%' y1='150%' x2='10%' y2='120%'><stop offset='10%' stop-color='black'><animate attributeName='stop-color' values='#7b8e9c; #8599d4; #ba2952; #baa429; black' dur='4700ms' begin='3s' repeatCount='indefinite' /></stop><stop offset='130%' stop-color='#7b8e9c'><animate attributeName='stop-color' values='yellow; #7b8e9c; #baa429; #8599d4; #ba2952; ' "
        ];


    event Minted(uint256 tokenId, address owner);
    error SvgNft__TokenUriNotFound();

    constructor(
        string memory _name,
        string memory _symbol
        
    ) ERC721Base( msg.sender, _name, _symbol
      , msg.sender, 0
    ) {

    }


    
    function mintTo(address _to, string memory _tokenURI) public override {
        require(_canMint(), "Not authorized to mint.");

        uint256 nextTokenId = nextTokenIdToMint();
        

        DynamicData memory dynamicData = DynamicData({
            owner: msg.sender,
            status: 0,
            mintingTime: block.timestamp,
            durationMs: 7000
        });


        tokenData[nextTokenId] = dynamicData;
        s_tokenIdToUri[nextTokenId] = tokenURI(nextTokenId);

        _setTokenURI(nextTokenId, s_tokenIdToUri[nextTokenId]);

        _safeMint(_to, 1, "");
    }



    function tokenURI(uint256 _id) public view override returns (string memory) {
       DynamicData storage dynamicData = tokenData[_id];    
       string memory durationMs = u2str(dynamicData.durationMs); 
    
       string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "#',u2str(_id),'",',
                    '"image": "data:image/svg+xml;base64,',Base64.encode(bytes(makeSVG(_id))),'",',
                    '"attributes": [{"trait_type": "duration_ms", "value": "',durationMs,'" }',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
 
    }

    function makeSVG(uint256 id) public view returns (string memory ) {

        string memory _svgData = svgData[id];        

        DynamicData storage dynamicData = tokenData[id];    
        string memory durationMs = u2str(dynamicData.durationMs);

         string memory res  = string(abi.encodePacked("<svg width='350px' height='350px' xmlns='http://www.w3.org/2000/svg'>",
                  "<linearGradient id='gradient'  x1=",
                  _svgData,
                  "dur='",durationMs,"ms' begin='0s' repeatCount='indefinite' /></stop></linearGradient><rect x='80' y='80' id='shape' width='200' height='200' fill='url(#gradient)'/></svg>"));
        return res;
    }

    
    /*
     * Dynamic function that provides an evolving dimension to the NFT.
     * The owner can change this duration parameter to alter the
     * shadow play of the NFT.
     */
    function dfChangeDuration(uint256 _tokenId, uint256 _durationMs)  public   {
        
        DynamicData storage dynamicData = tokenData[_tokenId];
        require(msg.sender == dynamicData.owner, "Only the owner can change the duration");

        dynamicData.durationMs = _durationMs;       

    }

    function getTokenData(uint256 tokenId) public view returns (address, uint256, uint256, uint256) {
        DynamicData memory dd = tokenData[tokenId];
        return (dd.owner, dd.status, dd.mintingTime, dd.durationMs);
    }

    function splitHash(string memory str) public pure returns(string[10] memory) {
        
        string[10]  memory res;       
        string      memory hash = TWStrings.toHexString(uint256(keccak256(abi.encodePacked(str))), 32);           
        bytes       memory a = bytes(hash);
        uint        s = 2;       

        for(uint i=0; i < 10; i++){                           
          res[i] = string(abi.encodePacked(a[s],a[s+1],a[s+2],a[s+3],a[s+4],a[s+5]));
          s  = s + 6;         
        } 

        return res;        
    }  

    function toUint256(string memory str) public pure returns (uint256 value) {

        bytes memory _bytes= bytes(str);
        assembly {value := mload(add(_bytes, 0x20))}
        return value/10**70;
    }

    function u2str(uint _i) internal pure returns (string memory _str) {
      if (_i == 0) { return "0";}
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}