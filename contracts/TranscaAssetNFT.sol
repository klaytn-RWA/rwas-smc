// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { IAggregator } from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";

contract TranscaAssetNFT is Initializable, ERC721Upgradeable ,ERC721URIStorageUpgradeable ,ERC721EnumerableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable {
    using Counters for Counters.Counter;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    IAggregator internal dataFeed;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    enum PhysicalType {
        GOLD,
        DIAMOND,
        OTHER
    }

    struct Asset { 
        uint256 _assetId;
        int256 _weight;
        string _indentifierCode;
        uint16 _assetType;
        uint256 _startTime;
        uint256 _expireTime;
        uint256 _userDefinePrice;
        uint256 _appraisalPrice;
    }

    Counters.Counter private _assetID;

    Asset[] private assets;

    mapping (uint256 => Asset) public physicalAssetAttribute;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Transca NFTs", "TSA");
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __ERC721URIStorage_init();


        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _pause();
    }

   function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setAggregator(address aggregatorProxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dataFeed = IAggregator(aggregatorProxy);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _burn(uint256 _in_tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable) whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE){
        super._burn(_in_tokenId);
    }

    event Issue(
        address indexed _userAddress,
        uint256 indexed _id,
        int256 _weight,
        string _indentifierCode,
        uint16 _assestType
    );

    function setAsset(address _userAddress, uint256 _id, int256 _weight, uint256 _startTime,uint256 _expireTime, string memory _indentifierCode, uint16 _assetType, uint256 _userDefinePrice, uint256 _appraisalPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Asset memory attribute = Asset({
            _assetId: _id,
            _weight: _weight,
            _indentifierCode: _indentifierCode,
            _assetType: _assetType,
            _startTime: _startTime, // mint time
            _expireTime: _expireTime,
            _userDefinePrice: _userDefinePrice,
            _appraisalPrice: _appraisalPrice
        });
        physicalAssetAttribute[_id] = attribute;

        emit Issue(
            _userAddress,
            _id,
            _weight,
            _indentifierCode,
            _assetType
        );
    } 

    function safeMint(address _to, int256 _in_weight, uint256 _in_expire_time, uint16 _in_assetType, string memory _in_identifierCode, string memory _in_token_uri, uint256 _in_user_define_price, uint256 in_appraisal_price) public whenNotPaused  onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256)  {
        uint256 assetId = _assetID.current();
        uint256 startTime = block.timestamp;
        _assetID.increment();
        PhysicalType assetType = PhysicalType(_in_assetType);
        assets.push(Asset({
            _assetId: assetId,
            _weight : _in_weight,
            _indentifierCode: _in_identifierCode,
            _assetType: uint16(assetType),
            _startTime : startTime,
            _expireTime: _in_expire_time,
            _userDefinePrice: _in_user_define_price,
            _appraisalPrice: in_appraisal_price
        }));
        setAsset(_to, assetId, _in_weight, startTime, _in_expire_time, _in_identifierCode, uint16(assetType), _in_user_define_price, in_appraisal_price);
        _safeMint(_to, assetId);
        _setTokenURI(assetId, _in_token_uri);
        return assetId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function getLatestData() public view returns (int256) {
        (,int256 answer_, , , ) = dataFeed.latestRoundData();
        return answer_;
    }

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

    function getAssetDetail(uint256 _in_asset_id)
        public
        view
        returns (
           AssetR memory
        )
    {
        AssetR memory result;
        int256 price = getLatestData();
        int256 tempOraklPrice = 0;
        Asset memory asset = assets[_in_asset_id];
        if (asset._assetType == 0) {
            tempOraklPrice = price*asset._weight;
        }
        address owner = ERC721Upgradeable.ownerOf(_in_asset_id);
        result._owner = owner;
        result._assetId = _in_asset_id;
        result._weight = asset._weight;
        result._indentifierCode = asset._indentifierCode;
        result._assetType = asset._assetType;
        result._startTime = asset._startTime;
        result._expireTime = asset._expireTime;
        result._oraklPrice = tempOraklPrice;
        result._userDefinePrice = asset._userDefinePrice;
        result._appraisalPrice = asset._appraisalPrice;
        return result;
    }

    


    function getAllAssetByUser() public view returns(AssetR[] memory){
        uint256 tokenIds = balanceOf(msg.sender);
        AssetR[] memory result = new AssetR[](tokenIds);
        for(uint i=0; i < tokenIds; i++){
            uint256 id = tokenOfOwnerByIndex(msg.sender,i);
            result[i] = getAssetDetail(id);
        }
        return result;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}