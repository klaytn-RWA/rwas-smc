// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./TranscaAssetNFT.sol";
import "./interfaces/ITransca.sol";


contract Lottery is Initializable, IERC721ReceiverUpgradeable, AccessControlUpgradeable, PausableUpgradeable {

    using Counters for Counters.Counter;

    Counters.Counter public lotteryId;

    TranscaAssetNFT public assetNft;
    IERC20 public token;


    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant LOTTERY_ADMIN_ROLE = keccak256("LOTTERY_ADMIN_ROLE");

    struct LotterySession {
        uint256 id;
        uint256 assetId;
        uint256 createdAt;
        uint256 duration;
        uint256 expiredAt;
        address winner;
        uint256 winNumber;
        uint256 totalNumber;
        uint256 pricePerNumber;
    }

    struct BuyOffer {
        uint256 number;
        address buyer;
    }
    
    mapping(uint256=> LotterySession) public lotteries;

    mapping(uint256 => mapping(uint256 => address)) public buyers;


    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(LOTTERY_ADMIN_ROLE, msg.sender);

        _pause();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setAsset(address _assetNftAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetNft = TranscaAssetNFT(_assetNftAddress);
    }

    function setToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
    }

    function createLottery (uint256 _assetId, uint256 _duration) public onlyRole(LOTTERY_ADMIN_ROLE) whenNotPaused {
        uint256 _lotteryId = lotteryId.current();

        uint256 startTime = block.timestamp;
        
        assetNft.safeTransferFrom(msg.sender, address(this), _assetId);

        LotterySession memory _lottery = LotterySession({
            id: _lotteryId,
            assetId: _assetId,
            createdAt: startTime,
            duration: _duration,
            expiredAt: startTime + _duration,
            winner: address(0),
            winNumber: 0,
            totalNumber: 5,
            pricePerNumber: 1
        });

        lotteries[_lotteryId] = _lottery;

        lotteryId.increment();
    }

    function buySlot (uint256 _lotteryId, uint256 _number, uint256 _amount) public payable returns (bool) {
        LotterySession memory _lottery = lotteries[_lotteryId];

        require(_lotteryId == lotteryId.current()-1 && lotteryId.current() > 0, "lottery session not exited"); 
        require(block.timestamp < _lottery.expiredAt, "lottery session expire");
        require(buyers[_lottery.id][_number] == address(0), "lottery number solded");

        if(_amount == _lottery.pricePerNumber){
            require(token.transferFrom(msg.sender, address(this), _lottery.pricePerNumber), "Transfering the lottery amount to the smc failed");
            buyers[_lottery.id][_number] = msg.sender; 
        }

        return true;
    }

    function updateWinNumber (uint256 _number, uint256 _lotteryId) public onlyRole(LOTTERY_ADMIN_ROLE) whenNotPaused {
        LotterySession memory _lottery = lotteries[_lotteryId];
        require(_lotteryId == lotteryId.current()-1 && lotteryId.current() > 0, "lottery session not exited"); 
        require(_number <= _lottery.totalNumber, "lottery number not exited"); 

        if (_lottery.winNumber == 0 && _lottery.winner == address(0)){
            _lottery.winNumber = _number;
            if(buyers[_lottery.id][_number] != address(0)){
                assetNft.safeTransferFrom(address(this), buyers[_lottery.id][_number], _lottery.assetId);
                _lottery.winner = buyers[_lottery.id][_number];
                lotteries[_lotteryId] = _lottery;
            }
        }

    }

    function getLottery (uint256 _lotteryId) public view returns (LotterySession memory) {
        LotterySession memory _lottery = lotteries[_lotteryId];
        return _lottery;
    }

    function getCurrentLottery () public view returns (LotterySession memory){
        require(lotteryId.current() > 0, "lottery session not exited"); 
        LotterySession memory _lottery = lotteries[lotteryId.current()-1];
        return _lottery;
    }

    function getLotteryBuyers (uint256 _lotteryId) public view returns (BuyOffer[] memory) {
        LotterySession memory _lottery = lotteries[_lotteryId];
        BuyOffer[] memory _buyers = new BuyOffer[](_lottery.totalNumber);
        for (uint i = 0; i < _lottery.totalNumber; i++) {
            BuyOffer memory _buy = BuyOffer({
                number: i,
                buyer: buyers[_lottery.id][i]
            });
            _buyers[i] = _buy;
        }
        return _buyers;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
