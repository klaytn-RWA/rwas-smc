// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TranscaAssetNFT.sol";
import "./TranscaBundleNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TranscaIntermediation is Initializable, AccessControlUpgradeable, PausableUpgradeable, IERC721ReceiverUpgradeable {
    using Counters for Counters.Counter;
    IERC20 public token;
    TranscaAssetNFT public assetNft;
    TranscaBundleNFT public bundleNft;
    IERC721 public splitNft;

    struct BorrowReq {
        uint256 borrowReqId;
        //
        uint256 nftId;
        address nftAddress;
        // step 1
        address creator;
        uint256 createdAt;
        // attr
        uint256 amount;
        uint256 minAmount;
        uint256 duration; // duration of loan
        //
        uint256 lendOfferReqId; // internal, list
        // step 2
        address lender;
        uint256 borrowedAt;
        // step 3
        bool returned;
        uint256 returnedAt;
        // step 4.1, returned (borrower withdraw nft, send money to lender)
        bool withdrawed;
        uint256 withdrawedAt;
        // step 4.2, not returned (nft)
        bool lenderWithdrawed;
        uint256 lenderWithdrawedAt;
        //
        bool cancelled;
    }

    struct LendOfferReq {
        uint256 lendReqId;
        uint256 borrowReqId;
        uint256 borrowLendReqId;
        //
        address creator;
        uint256 createdAt;
        //
        uint256 amount;
        //
        bool cancelled;
    }

    Counters.Counter public borrowReqId;
    Counters.Counter public lendOfferReqId; // global

    mapping(uint256 => BorrowReq) public borrows;
    mapping(uint256 => LendOfferReq) public lends;
    mapping(uint256 => mapping(uint256 => LendOfferReq)) public lendOffersByBorrow;

    event CreateBorrowAsset(uint256 id, uint256 indexed nftId, bool isBundle, address indexed creator, uint256 createAt, uint256 amount, uint256 minAmount, uint256 duration);

    // event CreateLendOfferForBorrowReq(uint256 lendId, bytes32 borrowId, uint256 lendAmount, uint256 interateRateAmount, uint256 duration, address lender);

    function initialize() public initializer {}

    function setAsset(address _assetNftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetNft = TranscaAssetNFT(_assetNftAddress);
    }

    function setBundle(address _bundleNftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bundleNft = TranscaBundleNFT(_bundleNftAddress);
    }

    function setToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
    }

    function isERC721Contract(address contractAddress) external view returns (bool) {
        IERC721 nftContract = IERC721(contractAddress);

        // Check if the contract implements the necessary functions
        try nftContract.ownerOf(0) returns (address) {
            // ERC721 contract found
            return true;
        } catch {
            // Not an ERC721 contract
            return false;
        }
    }

    function createBorrow(uint256 _nftId, address _nftAddress, uint256 _amount, uint256 _minAmount, uint256 _duration) public returns (uint256) {
        // action
        require(this.isERC721Contract(_nftAddress), "NFT Only");
        IERC721 nftContract = IERC721(_nftAddress);
        address owner = IERC721(_nftAddress).ownerOf(_nftId);

        require(msg.sender == owner, "Only the owner can create borrow request");
        require(_amount > 0, "Loan amount should be bigger than 0");
        require(_minAmount > 0, "Min amount should be bigger than 0");
        require(_minAmount < _amount, "Min amount should be smaller than loan amount");
        require(_duration > 0, "Duration loan should be bigger than 0min(s)"); // minutes

        uint256 _borrowReqId = borrowReqId.current();

        BorrowReq memory _borrow = BorrowReq({
            borrowReqId: _borrowReqId,
            nftId: _nftId,
            nftAddress: _nftAddress,
            creator: msg.sender,
            createdAt: block.timestamp,
            amount: _amount,
            minAmount: _minAmount,
            duration: _duration,
            lendOfferReqId: 0,
            lender: address(0),
            borrowedAt: 0,
            returned: false,
            returnedAt: 0,
            withdrawed: false,
            withdrawedAt: 0,
            lenderWithdrawed: false,
            lenderWithdrawedAt: 0,
            cancelled: false
        });

        borrows[_borrowReqId] = _borrow;

        nftContract.safeTransferFrom(msg.sender, address(this), _nftId);

        borrowReqId.increment();

        // TO-DO: event

        return _nftId;
    }

    function createQuickBorrow(uint256 _nftId, address _nftAddress, uint256 _duration) public returns (uint256) {
        // action
        require(this.isERC721Contract(_nftAddress), "NFT Only");
        IERC721 nftContract = IERC721(_nftAddress);
        address owner = IERC721(_nftAddress).ownerOf(_nftId);

        require(msg.sender == owner, "Only the owner can create borrow request");
        require(_duration > 0, "Duration loan should be bigger than 0min(s)"); // minutes

        address lender = address(0);
        uint256 borrowedAt = 0;
        uint256 amount = 0;

        if (_nftAddress == address(assetNft)) {
            lender = address(this);
            borrowedAt = block.timestamp;
            TranscaAssetNFT _nftContract = TranscaAssetNFT(_nftAddress);
            ITransca.AssetR memory nft = _nftContract.getAssetDetail(_nftId);

            require(token.transferFrom(address(this), msg.sender, uint256(nft.oraklPrice)), "Transfering the offered amount to the borrower failed");
        }

        if (_nftAddress == address(assetNft)) {
            lender = address(this);
            borrowedAt = block.timestamp;

            TranscaBundleNFT _nftContract = TranscaBundleNFT(_nftAddress);
            require(token.transferFrom(address(this), msg.sender, uint256(_nftContract.getValue(_nftId))), "Transfering the offered amount to the borrower failed");
        }

        uint256 _borrowReqId = borrowReqId.current();

        BorrowReq memory _borrow = BorrowReq({
            borrowReqId: _borrowReqId,
            nftId: _nftId,
            nftAddress: _nftAddress,
            creator: msg.sender,
            createdAt: block.timestamp,
            amount: amount,
            minAmount: amount,
            duration: _duration,
            lendOfferReqId: 0,
            lender: lender,
            borrowedAt: borrowedAt,
            returned: false,
            returnedAt: 0,
            withdrawed: false,
            withdrawedAt: 0,
            lenderWithdrawed: false,
            lenderWithdrawedAt: 0,
            cancelled: false
        });

        borrows[_borrowReqId] = _borrow;

        nftContract.safeTransferFrom(msg.sender, address(this), _nftId);

        borrowReqId.increment();

        // TO-DO: event

        return _nftId;
    }

    function getAllBorrows() public view returns (BorrowReq[] memory) {
        BorrowReq[] memory _borrows = new BorrowReq[](borrowReqId.current());

        for (uint i = 0; i < borrowReqId.current(); i++) {
            if (!borrows[i].cancelled) {
                _borrows[i] = borrows[i];
            }
        }

        return _borrows;
    }

    function getAllBorrowsWithCancelled() public view returns (BorrowReq[] memory) {
        BorrowReq[] memory _borrows = new BorrowReq[](borrowReqId.current());

        for (uint i = 0; i < borrowReqId.current(); i++) {
            _borrows[i] = borrows[i];
        }

        return _borrows;
    }

    function getAllBorrowsWithAccepted() public view returns (BorrowReq[] memory) {
        BorrowReq[] memory _borrows = new BorrowReq[](borrowReqId.current());

        for (uint256 i = 0; i < borrowReqId.current(); i++) {
            if (borrows[i].borrowedAt > 0) {
                _borrows[i] = borrows[i];
            }
        }

        return _borrows;
    }

    function getAllDoneBorrows() public view returns (BorrowReq[] memory) {
        BorrowReq[] memory _borrows = new BorrowReq[](borrowReqId.current());

        for (uint i = 0; i < borrowReqId.current(); i++) {
            if (borrows[i].withdrawed || borrows[i].lenderWithdrawed) {
                _borrows[i] = borrows[i];
            }
        }

        return _borrows;
    }

    function createLendOffer(uint256 _borrowId, uint256 _amount) public {
        // action
        BorrowReq memory borrowReq = borrows[_borrowId];
        address borrower = borrowReq.creator;

        require(borrower != msg.sender, "Can not lending for yourself");
        require(_amount > 0, "Lend amount should be bigger than 0");
        require(_amount <= borrowReq.amount, "Lend amount should be smaller than max of borrow request amount");
        require(borrowReq.borrowedAt == 0, "Borrowed");
        require(borrowReq.cancelled == false, "Borrow cancelled");

        uint256 _lendOfferReqId = lendOfferReqId.current();

        uint256 time = block.timestamp;

        LendOfferReq memory _offer = LendOfferReq({
            lendReqId: _lendOfferReqId,
            borrowReqId: borrowReq.borrowReqId,
            borrowLendReqId: borrowReq.lendOfferReqId,
            creator: msg.sender,
            createdAt: time,
            amount: _amount,
            cancelled: false
        });

        lends[_lendOfferReqId] = _offer;
        lendOffersByBorrow[_lendOfferReqId][borrowReq.lendOfferReqId] = _offer;

        borrowReq.lendOfferReqId++;

        if (_amount == borrowReq.amount) {
            // borrower accepted
            require(token.transferFrom(msg.sender, address(this), _amount), "Transfering the offered amount to the smc failed");
            borrowReq.lender = msg.sender;
            borrowReq.borrowedAt = time;
        }

        borrows[borrowReq.borrowReqId] = borrowReq;

        lendOfferReqId.increment();

        // TO-DO: event
    }

    function getBorrowReqById(uint256 _borrowId) public view returns (BorrowReq memory) {
        return borrows[_borrowId];
    }

    function isOverDuration(uint256 _borrowId) public view returns (bool) {
        // đã quá thời gian cần hoàn lại tiền vay
        return (block.timestamp > this.borrowDuration(_borrowId));
    }

    function isNftLockedForBorrower(uint256 _borrowId) public view returns (bool) {
        if (this.isOverDuration(_borrowId)) {
            if (this.isReturned(_borrowId)) {
                return false; // được lấy
            }
        } else {
            if (this.isCancelled(_borrowId)) {
                return false; // được lấy
            }
        }

        return true;
    }

    function isNftLockedForLender(uint256 _borrowId) public view returns (bool) {
        if (this.isOverDuration(_borrowId)) {
            if (this.isReturned(_borrowId)) {
                return true;
            } else {
                return false; // được lấy
            }
        }

        return true;
    }

    function isBorrowed(uint256 _borrowId) public view returns (bool) {
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);
        return _borrow.borrowedAt > 0;
    }

    function isReturned(uint256 _borrowId) public view returns (bool) {
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);
        return _borrow.returnedAt > 0;
    }

    function isCancelled(uint256 _borrowId) public view returns (bool) {
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);
        return _borrow.cancelled;
    }

    function isLenderClamable(uint256 _borrowId) public view returns (bool) {
        // đã quá thời gian và lender có thể lấy nft
        return (this.isOverDuration(_borrowId) && !this.isReturned(_borrowId));
    }

    function borrowDuration(uint256 _borrowId) public view returns (uint256) {
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);
        return _borrow.borrowedAt + _borrow.duration * 60;
    }

    function cancelBorrow(uint256 _borrowId) public returns (bool) {
        // action
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);

        require(msg.sender == _borrow.creator, "Only the owner can create borrow request");

        IERC721 nftContract = IERC721(_borrow.nftAddress);

        if (!this.isBorrowed(_borrowId)) {
            _borrow.cancelled = true;
            borrows[_borrow.borrowReqId] = _borrow;

            nftContract.safeTransferFrom(address(this), msg.sender, _borrow.nftId);

            return true;
        }

        // TO-DO: event

        return false;
    }

    function acceptOffer(uint256 _borrowId) public view returns (bool) {
        // action
    }

    function cancelOffer(uint256 _borrowId) public view returns (bool) {
        // action
    }

    function returnTheMoney(uint256 _borrowId) public returns (bool) {
        // action
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);

        require(msg.sender == _borrow.creator, "Only the owner can create borrow request");
        require(_borrow.cancelled == false, "Only not cancel yet");
        require(_borrow.borrowedAt > 0, "Only borrowed");
        require(_borrow.returnedAt == 0, "Only not return yet");
        require(!this.isOverDuration(_borrowId), "Over duration");
        require(_borrow.lenderWithdrawedAt > 0, "Only not done yet");
        require(token.transferFrom(msg.sender, _borrow.lender, _borrow.amount), "Transfering the return amount to the lender failed");

        _borrow.returned = true;
        _borrow.returnedAt = block.timestamp;

        IERC721 nftContract = IERC721(_borrow.nftAddress);
        nftContract.safeTransferFrom(address(this), msg.sender, _borrow.nftId);

        _borrow.withdrawed = true;
        _borrow.withdrawedAt = block.timestamp;

        borrows[_borrow.borrowReqId] = _borrow;

        // TO-DO: event

        return true;
    }

    function lenderClaim(uint256 _borrowId) public returns (bool) {
        // action
        BorrowReq memory _borrow = this.getBorrowReqById(_borrowId);

        require(this.isOverDuration(_borrowId), "Only over duration");
        require(msg.sender == _borrow.lender, "Only the lender can claim");
        require(!this.isReturned(_borrowId), "Only not return money yet");

        IERC721 nftContract = IERC721(_borrow.nftAddress);

        nftContract.safeTransferFrom(address(this), msg.sender, _borrow.nftId);

        _borrow.lenderWithdrawed = true;
        _borrow.lenderWithdrawedAt = block.timestamp;

        borrows[_borrow.borrowReqId] = _borrow;

        // TO-DO: event

        return true;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// mint nfts
// usdt
// deposit usdt to this contract
// create borrow
// create lend
//
