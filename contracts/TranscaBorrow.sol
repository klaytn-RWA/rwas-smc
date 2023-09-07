// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";


contract TranscaBorrow is Initializable, IERC721ReceiverUpgradeable {
    IERC20 public token;
    IERC721 public asset;
    IERC721 public bundle;

    function initialize(address _token, address _asset, address _bundle) public initializer {
        token = IERC20(_token);
        asset = IERC721(_asset);
        bundle = IERC721(_bundle);
    }

    mapping(uint256 => BorrowReq) public borrowRequestList;
    // mapping(bytes32 => LendOfferReq) public lendOfferRequestList;
    uint256 public countBorrowReq;

    mapping(bytes32 => LendOfferReq[]) public lendOfferRequestList;

    struct BorrowReq {
        bytes32 _borrowReqId;
        uint256 _nftId;
        bool    _isBundle; //Bunle or asset
        address _borrower;
        uint256 _loanAmount;
        uint256 _interateRateAmount;
        uint256 _duration;
        uint256 _borrowCreateAt;
    }
    
    struct LendOfferReq {
        bytes32 _lendReqId;
        uint256 _lendAmountOffer;
        uint256 _interateRateAmountOffer;
        uint256 _durationOffer;
        address _lender;
    }

    event __createBorrowAsset(bytes32 id, uint256 indexed nftId, bool isBundle, address indexed borrower, uint256 loanAmount, uint256 interateRateAmount, uint256 duration, uint256 createAt);
    event __createLendOfferForBorrowReq(bytes32 lendId, bytes32 borrowId, uint256 lendAmount, uint256 interateRateAmount, uint256 duration, address lender);

    function createBorrowAsset(uint256 _inNFTId, bool _inIsBundle, uint256 _inLoanAmount ,uint256 _inInterateRateAmount, uint256 _inDuration) public returns (uint256) {
        address assetOwner = asset.ownerOf(_inNFTId);

        require(msg.sender == assetOwner, "Only the owner can create borrow request");
        require(_inLoanAmount > 0, "Loan amount should be bigger than 0");
        require(_inInterateRateAmount > 0, "Interate rate amount should be bigger than 0");
        require(_inInterateRateAmount < _inLoanAmount, "Interate rate amount should be smaller than loan amount");
        require(_inDuration > 0, "Duration loan should be better than 0");

        bytes32 borrowReqId = keccak256(abi.encodePacked(block.timestamp, assetOwner, _inNFTId, _inLoanAmount, _inInterateRateAmount, _inDuration));
        borrowRequestList[_inNFTId] = BorrowReq({_borrowReqId: borrowReqId, _nftId: _inNFTId, _borrower: msg.sender, _loanAmount: _inLoanAmount, _isBundle: _inIsBundle,_interateRateAmount:_inInterateRateAmount, _duration: _inDuration, _borrowCreateAt: block.timestamp});
        countBorrowReq++;

        asset.safeTransferFrom(msg.sender, address(this), _inNFTId);

        emit __createBorrowAsset(borrowReqId, _inNFTId, _inIsBundle, msg.sender, _inLoanAmount, _inInterateRateAmount, _inDuration, block.timestamp);

        return _inNFTId;
    }

    function getAllBorrowsRequest() public view returns (BorrowReq[] memory){ // Leding - UI
        BorrowReq[] memory borrows = new BorrowReq[](countBorrowReq);
        for(uint i = 0; i < countBorrowReq; i++) {
            borrows[i] = borrowRequestList[i];
        }
        return borrows;
    }

    function createLendOfferForBorrowReq(uint256 _inBorrowId, uint256 _inLendAmount, uint256 _inInterateRateAmount, uint256 _inDuration) public  {
        BorrowReq memory borrowReq = borrowRequestList[_inBorrowId];
        address borrower = borrowReq._borrower;
        require(borrower != msg.sender, "Unauthorized user");
        require(_inLendAmount > 0, "Lend amount should be bigger than 0");
        require(_inInterateRateAmount > 0, "Interate rate amount should be bigger than 0");
        require(_inDuration > 0, "Duration should be bigger than 0");

        bytes32 offerId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _inBorrowId, _inLendAmount, _inInterateRateAmount, _inDuration));
        lendOfferRequestList[borrowReq._borrowReqId].push(
            LendOfferReq({_lendReqId: offerId, _lendAmountOffer: _inLendAmount, _interateRateAmountOffer: _inInterateRateAmount, _durationOffer:_inDuration, _lender: msg.sender})
        );

        require(
            token.transferFrom(msg.sender, address(this), _inLendAmount + _inInterateRateAmount),
            "Transfering the offered amount to the smc failed"
        );

        emit __createLendOfferForBorrowReq(offerId, borrowReq._borrowReqId, _inLendAmount, _inInterateRateAmount, _inDuration, msg.sender);
    }

    function getAllLendReqByNFTId(uint256 _nftId) public view returns (LendOfferReq[] memory){
        BorrowReq memory borrowReq = borrowRequestList[_nftId];
        LendOfferReq[] memory lendOffers = lendOfferRequestList[borrowReq._borrowReqId];
        return lendOffers;
    }



    function acceptBorrowRequest() public returns (uint256) {

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}



