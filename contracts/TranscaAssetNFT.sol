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

contract TranscaAssetNFT is Initializable,ERC721Upgradeable ,ERC721URIStorageUpgradeable ,ERC721EnumerableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable {
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

    function setAsset(address _userAddress, uint256 _id, int256 _weight, uint256 _startTime,uint256 _expireTime, string memory _indentifierCode, uint16 _assetType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Asset memory attribute = Asset({
            _assetId: _id,
            _weight: _weight,
            _indentifierCode: _indentifierCode,
            _assetType: _assetType,
            _startTime: _startTime, // mint time
            _expireTime: _expireTime
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

    function safeMint(address _to, int256 _in_weight, uint256 _in_expire_time, uint16 _in_assetType, string memory _in_identifierCode, string memory _in_token_uri) public whenNotPaused  onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256)  {
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
            _expireTime: _in_expire_time
        }));
        setAsset(_to, assetId, _in_weight, startTime, _in_expire_time, _in_identifierCode, uint16(assetType));
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

    function getAssetDetail(uint256 _in_asset_id)
        public
        view
        returns (
            address,
            uint256,
            int256,
            string memory,
            uint16,
            uint256,
            uint256,
            int256
        )
    {
        int256 price = getLatestData();
        Asset memory asset = assets[_in_asset_id];
        address  owner = ERC721Upgradeable.ownerOf(_in_asset_id);
        return (
            owner,
            asset._assetId,
            asset._weight,
            asset._indentifierCode,
            asset._assetType,
            asset._startTime,
            asset._expireTime,
            price*asset._weight
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}