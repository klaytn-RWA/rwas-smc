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
import {IAggregator} from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";
import "./interfaces/ITransca.sol";

contract TranscaAssetNFT is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable
{
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

    Counters.Counter public assetId;
    mapping(uint256 => ITransca.Asset) public assets;

    //multisign
    struct MintRequest {
        address to;
        int256 weight;
        uint256 expireTime;
        uint16 assetType;
        string indentifierCode;
        string tokenUri;
        int256 userDefinePrice;
        int256 appraisalPrice;
        bool executed;
        uint numConfirmations;
        bool isAuditSign;
        bool isStockerSign;
        bool isTranscaSign;
    } 

    address public audit;
    address public stocker;
    address public transca;

    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;
    mapping(uint => mapping(address => bool)) public isConfirmed;
    MintRequest[] public mintRequests;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < mintRequests.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!mintRequests[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier notMultiSign(address _signer) {
        require(_signer == audit || _signer == stocker || _signer == transca, "sign rejected!");
        _;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Transca NFTs", "TSA");

        __AccessControl_init();
        __Pausable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _pause();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setAggregator(address aggregatorProxy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dataFeed = IAggregator(aggregatorProxy);
    }

    function setOwnerMultiSign(address _transca, address _audit, address _stocker) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transca = _transca;
        audit = _audit;
        stocker = _stocker;
        numConfirmationsRequired = 3;
    }

    function requestMintRWA ( 
        // address _to,
        int256 _weight,
        uint256 _expireTime,
        uint16 _assetType,
        string memory _indentifierCode,
        string memory _tokenUri,
        int256 _userDefinePrice,
        int256 _appraisalPrice
    ) public {
        mintRequests.push(
            MintRequest({
                to: msg.sender,
                weight: _weight,
                expireTime: _expireTime,
                assetType: _assetType,
                indentifierCode: _indentifierCode,
                tokenUri: _tokenUri,
                userDefinePrice: _userDefinePrice,
                appraisalPrice: _appraisalPrice,
                executed: false,
                numConfirmations: 0,
                isAuditSign: false,
                isStockerSign: false,
                isTranscaSign: false
            })
        );
    }

    function confirmTransaction( uint _txIndex ) public txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) notMultiSign(msg.sender) {
        MintRequest memory transaction = mintRequests[_txIndex];
        if(msg.sender == audit) {
            transaction.isAuditSign = true;
        }
        if(msg.sender == stocker) {
            transaction.isStockerSign = true;
        }
        if(msg.sender == transca) {
            transaction.isTranscaSign = true;
        }
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        mintRequests[_txIndex] = transaction;
    } 

    function executeMint(
        uint _txIndex
    ) public onlyRole(MINTER_ROLE) txExists(_txIndex) notExecuted(_txIndex) notMultiSign(msg.sender) returns (MintRequest memory) {
        MintRequest memory transaction = mintRequests[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        uint256 _assetId = assetId.current();

        uint256 startTime = block.timestamp;

        PhysicalType assetType = PhysicalType(transaction.assetType);

        _safeMint(transaction.to, _assetId);
        _setTokenURI(_assetId, transaction.tokenUri);
        setAsset(transaction.to, _assetId, transaction.weight, startTime, transaction.expireTime, transaction.indentifierCode, uint16(assetType), transaction.userDefinePrice, transaction.appraisalPrice);

        assetId.increment();

        transaction.executed = true;

        mintRequests[_txIndex] = transaction;

        return transaction;
    }

    function getAllMintRequest () public view returns (MintRequest[] memory) {
        return mintRequests;
    }

    function getAllMintRequestByUser (address _user) public view returns (MintRequest[] memory) {
        MintRequest[] memory result = new MintRequest[](10);
        for (uint i = 0; i < mintRequests.length; i++) {
            if (_user == mintRequests[i].to) {
                result[i] = mintRequests[i];
            }
        }
        return result;
    }

    event Issue(address indexed _userAddress, uint256 indexed _id, int256 _weight, string _indentifierCode, uint16 _assestType);


    function _burn(uint256 _in_tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable) whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(_in_tokenId);
    }

    function setAsset(
        address _userAddress,
        uint256 _id,
        int256 _weight,
        uint256 _startTime,
        uint256 _expireTime,
        string memory _indentifierCode,
        uint16 _assetType,
        int256 _userDefinePrice,
        int256 _appraisalPrice
    ) internal onlyRole(MINTER_ROLE) {
        ITransca.Asset memory attribute = ITransca.Asset({
            assetId: _id,
            weight: _weight,
            indentifierCode: _indentifierCode,
            assetType: _assetType,
            startTime: _startTime, // mint time
            expireTime: _expireTime,
            userDefinePrice: _userDefinePrice,
            appraisalPrice: _appraisalPrice
        });
        assets[_id] = attribute;

        emit Issue(_userAddress, _id, _weight, _indentifierCode, _assetType);
    }

    function safeMint(
        address _to,
        int256 _weight,
        uint256 _expireTime,
        uint16 _assetType,
        string memory _indentifierCode,
        string memory _tokenUri,
        int256 _userDefinePrice,
        int256 _appraisalPrice
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 _assetId = assetId.current();

        uint256 startTime = block.timestamp;

        PhysicalType assetType = PhysicalType(_assetType);

        _safeMint(_to, _assetId);
        _setTokenURI(_assetId, _tokenUri);
        setAsset(_to, _assetId, _weight, startTime, _expireTime, _indentifierCode, uint16(assetType), _userDefinePrice, _appraisalPrice);

        assetId.increment();

        return _assetId;
    }

    function getLatestData() public view returns (int256) {
        (, int256 price, , , ) = dataFeed.latestRoundData();
        return price;
    }

    function getAssetDetail(uint256 _assetId) public view returns (ITransca.AssetR memory) {
        ITransca.AssetR memory result;

        int256 price = getLatestData();
        int256 _oraklPrice = 0;

        ITransca.Asset memory asset = assets[_assetId];

        if (asset.assetType == 0) {
            _oraklPrice = price * asset.weight;
        }

        address owner = ERC721Upgradeable.ownerOf(_assetId);
        result.owner = owner;
        result.assetId = _assetId;
        result.oraklPrice = _oraklPrice;
        result.weight = asset.weight;
        result.indentifierCode = asset.indentifierCode;
        result.assetType = asset.assetType;
        result.startTime = asset.startTime;
        result.expireTime = asset.expireTime;
        result.userDefinePrice = asset.userDefinePrice;
        result.appraisalPrice = asset.appraisalPrice;
        return result;
    }

    function getAssetDetailNonOracle(uint256 _assetId) public view returns (ITransca.Asset memory) {
        ITransca.Asset memory result;
        ITransca.Asset memory asset = assets[_assetId];
        result.assetId = _assetId;
        return asset;
    }

    function getAllAssetByUser(address userAddress) public view returns (ITransca.AssetR[] memory) {
        uint256 tokenIds = balanceOf(userAddress);

        ITransca.AssetR[] memory result = new ITransca.AssetR[](tokenIds);

        for (uint i = 0; i < tokenIds; i++) {
            uint256 id = tokenOfOwnerByIndex(userAddress, i);
            result[i] = getAssetDetail(id);
        }

        return result;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
