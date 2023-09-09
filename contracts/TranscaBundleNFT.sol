// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TranscaAssetNFT.sol";
import "./interfaces/ITransca.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IAggregator} from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TranscaBundleNFT is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    IERC721ReceiverUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable
{
    using Counters for Counters.Counter;
    using AddressUpgradeable for address;

    TranscaAssetNFT public assetNft;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct TranscaBundle {
        uint256 bundleId;
        uint256[] assetIds;
    }

    Counters.Counter public bundleId;
    mapping(uint256 => TranscaBundle) public bundles;

    event Issue(address indexed _userAddress, uint256 indexed _id, uint256[] _ids);

    function initialize() public initializer {
        __ERC721_init("Transca Bundle NFTs", "TSB");

        __AccessControl_init();
        __Pausable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

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

    function setAsset(address _assetNftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetNft = TranscaAssetNFT(_assetNftAddress);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getAssetAttribute(uint256 _id) public view returns (ITransca.AssetR memory) {
        ITransca.AssetR memory att = assetNft.getAssetDetail(_id);
        return att;
    }

    function deposit(uint256[] memory _nftIds) public returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_nftIds.length);

        for (uint256 index = 0; index < _nftIds.length; index++) {
            assetNft.safeTransferFrom(msg.sender, address(this), _nftIds[index]);
            ids[index] = assetNft.getAssetDetailNonOracle(_nftIds[index]).assetId;
        }

        safeMint(msg.sender, ids);

        return ids;
    }

    function getValue(uint256 _bundleId) public view returns (int256) {
        TranscaBundle memory _bundle = bundles[_bundleId];

        int256 total = 0;

        for (uint i = 0; i < _bundle.assetIds.length; i++) {
            ITransca.AssetR memory att = assetNft.getAssetDetail(_bundle.assetIds[i]);
            total += att.oraklPrice;
        }

        return total;
    }

    function safeMint(address _to, uint256[] memory _ids) private whenNotPaused returns (uint256) {
        uint256 _bundleId = bundleId.current();

        TranscaBundle memory bundle = TranscaBundle({bundleId: _bundleId, assetIds: _ids});

        _safeMint(_to, _bundleId);
        _setTokenURI(_bundleId, "https://ipfs.io/ipfs/QmQw37CrbijdhhX3ZfRYFU9nWqLbHUUwjpr6fZtuf9mKDv");

        bundles[_bundleId] = bundle;

        emit Issue(_to, _bundleId, _ids);

        bundleId.increment();

        return _bundleId;
    }

    function withdraw(uint256 _bundleId) public whenNotPaused returns (uint256[] memory) {
        address owner = ERC721Upgradeable.ownerOf(_bundleId);
        require(owner == msg.sender, "Not owner");

        TranscaBundle memory bundle = bundles[_bundleId];
        uint256[] memory ids = new uint256[](bundle.assetIds.length);

        for (uint256 index = 0; index < bundle.assetIds.length; index++) {
            assetNft.safeTransferFrom(address(this), msg.sender, bundle.assetIds[index]);
            ids[index] = bundle.assetIds[index];
        }

        _burn(_bundleId);

        delete bundles[_bundleId];
        return ids;
    }

    function getBundle(uint256 _bundleId) public view returns (TranscaBundle memory) {
        TranscaBundle memory bundle = bundles[_bundleId];
        return bundle;
    }

    function getAllBundleByOwner(address _userAddress) public view returns (TranscaBundle[] memory) {
        uint256 tokenIds = balanceOf(_userAddress);
        TranscaBundle[] memory result = new TranscaBundle[](tokenIds);

        require(tokenIds > 0, "NFTs count equal zero!");

        for (uint i = 0; i < tokenIds; i++) {
            uint256 id = tokenOfOwnerByIndex(_userAddress, i);
            result[i] = bundles[id];
        }
        return result;
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function _burn(uint256 _in_tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable) {
        super._burn(_in_tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
