// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITransca {
    struct AssetR {
        address owner;
        //
        uint256 assetId;
        //
        int256 weight;
        //
        string indentifierCode;
        //
        uint16 assetType;
        //
        uint256 startTime;
        uint256 expireTime;
        //
        int256 oraklPrice;
        int256 userDefinePrice;
        int256 appraisalPrice;
    }

    struct Asset {
        uint256 assetId;
        //
        int256 weight;
        //
        string indentifierCode;
        //
        uint16 assetType;
        //
        uint256 startTime;
        uint256 expireTime;
        //
        int256 userDefinePrice;
        int256 appraisalPrice;
    }
}
