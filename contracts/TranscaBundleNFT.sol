// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { IAggregator } from "@bisonai/orakl-contracts/src/v0.1/interfaces/IAggregator.sol";
import "./TranscaAssetNFT.sol";
import "./interfaces/ITransca.sol";

contract TranscaBundleNFT is Initializable, IERC721ReceiverUpgradeable, ERC721Upgradeable ,ERC721URIStorageUpgradeable ,ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable {
    using Counters for Counters.Counter;
    using AddressUpgradeable for address;
    TranscaAssetNFT assetContract;

    struct TranscaBundle {
        uint256 _bundleId;
        // address[] nftSC;
        uint256[] _assetIds;
    }

    Counters.Counter private _bundleId;
    TranscaBundle[] private bundles;

    mapping (uint256 => TranscaBundle) public transcaBundleAttribute;

    function initialize() public initializer {
        __ERC721_init("Transca Bundle NFTs", "TBN");
        __ERC721Enumerable_init();
      
        __ERC721Burnable_init();
        __ERC721URIStorage_init();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setAddress(address _address) public {
        assetContract = TranscaAssetNFT(_address);            
    }

    event Issue(
        address indexed _userAddress,
        uint256 indexed _id,
        uint256[] _ids
    );

    function setBundle(address _userAddress, uint256 _id, uint256[] memory _ids) public {
        TranscaBundle memory attribute = TranscaBundle({
            _bundleId: _id,
            _assetIds: _ids
        });
        transcaBundleAttribute[_id] = attribute;

        emit Issue(
            _userAddress,
            _id,
            _ids
        );
    } 

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }    

    function getAssetAttribute(uint256 _id) public view returns (ITransca.AssetR memory) {
        ITransca.AssetR memory att = assetContract.getAssetDetail(_id);
        return att;
    }

    function deposit(uint256[] memory _nftIds, bytes memory signature) public returns (uint256[] memory) {
        bytes32 message = keccak256(
            abi.encodePacked(_msgSender(), _nftIds)
        );
        require(recoverSigner(prefixed(message), signature) == msg.sender, "Auth signature not match");
        
        uint256[] memory ids = new uint256[](_nftIds.length);

        for (uint256 index = 0; index < _nftIds.length; index++) {
            assetContract.safeTransferFrom(msg.sender, address(this), _nftIds[index]);
            ids[index] = assetContract.getAssetDetailNonOracle(_nftIds[index])._assetId;
        }
        safeMint(msg.sender,ids);
        return ids;
        // [TO-DO] after deposit mint bundle - widthdraw - burn bundle
    }

    function safeMint(address _to, uint256[] memory _ids) private returns (uint256) {
        uint256 bundleId = _bundleId.current();
        bundles.push(TranscaBundle({
            _bundleId: bundleId,
            _assetIds: _ids
        }));
        setBundle(msg.sender,bundleId, _ids);
        _safeMint(_to, bundleId);
        return bundleId;
    }

    function getBundle(uint256 _in_bundle_id) public view returns (TranscaBundle memory) {
        TranscaBundle memory bundle = bundles[_in_bundle_id];
        return bundle;
    }

    

    function _burn(uint256 _in_tokenId) internal override(ERC721URIStorageUpgradeable, ERC721Upgradeable){
        super._burn(_in_tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable)  {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
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

    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}