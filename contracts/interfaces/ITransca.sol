// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
interface ITransca{
  struct AssetR {
        address _owner;
        uint256 _assetId;
        int256 _weight;
        string _indentifierCode;
        uint16 _assetType;
        uint256 _startTime;
        uint256 _expireTime;
        int256 _oraklPrice;
        uint256 _userDefinePrice;
        uint256 _appraisalPrice;
    }
}