import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers, upgrades } from "hardhat";

describe("Transca Vault assests", function () {
  // Contracts:
  let transcaAssetNFTContract: Contract;
  let transcaBundleNFTContract: Contract;
  let transcaBorrowContract: Contract;
  let transcaToken: Contract;

  // Address:
  let owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress;

  // Variable:
  const aggregatorProxyXAU = "0x555E072996d0335Ec63B448ddD507CB99379C723";

  const deploy = async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy
    const transcaTokenContractFactory = await ethers.getContractFactory("USDTSimulator");
    transcaToken = await (await transcaTokenContractFactory.deploy("USDT", "USDT")).deployed();
    console.log("7s200:token:contract", transcaToken.address);

    const transcaAssetNFTContractFactory = await ethers.getContractFactory("TranscaAssetNFT");
    const deployTranscaAssetNFT = await upgrades.deployProxy(transcaAssetNFTContractFactory);
    transcaAssetNFTContract = await deployTranscaAssetNFT.deployed();
    console.log("7s200:asset:contract", transcaAssetNFTContract.address);

    const transcaBundleNFTContractFactory = await ethers.getContractFactory("TranscaBundleNFT");
    const deployTranscaBundleNFT = await upgrades.deployProxy(transcaBundleNFTContractFactory);
    transcaBundleNFTContract = await deployTranscaBundleNFT.deployed();
    const setcontract = await transcaBundleNFTContract.setAddress(transcaAssetNFTContract.address);
    await setcontract.wait();
    console.log("7s200:bundle:contract", transcaBundleNFTContract.address);

    const transcaBorrowContractFactory = await ethers.getContractFactory("TranscaBorrow");
    const deployTranscaBorrow = await upgrades.deployProxy(transcaBorrowContractFactory, [transcaToken.address, transcaAssetNFTContract.address, transcaBundleNFTContract.address]);
    transcaBorrowContract = await deployTranscaBorrow.deployed();
    console.log("7s200:borrow:contract", transcaBorrowContract.address);
  };

  const attach = async () => {};

  const unpause = async () => {
    const u1 = await transcaAssetNFTContract.connect(owner).unpause();
    const u1wait = await u1.wait();
  };

  const pause = async () => {
    await expect(transcaAssetNFTContract.connect(owner).pause()).to.not.reverted;
    await expect(transcaAssetNFTContract.connect(addr1).pause()).to.be.reverted;
  };

  describe("Mint", function () {
    // NFT attribute
    const now = new Date().getTime();

    const expire = now + 1_000;
    const weight = ethers.utils.parseUnits("1.5", "ether");

    const expireTime = ethers.BigNumber.from(expire);

    const assetTypeGOLD = ethers.BigNumber.from(0);
    const assetTypeDIAMOND = ethers.BigNumber.from(1);
    const assetTypeOTHER = ethers.BigNumber.from(2);

    const indentifierCode = "GOLDCODE1";

    const tokenURI = "https://ipfs.io/ipfs/QmRkk4SkhzxKs7s9EkxP9zU9VpFfEMWRT3aYbRtdiE8oUY";
    const tokenURIDiamond = "https://ipfs.io/ipfs/QmRYkXnQSvyKVJ9iDJ27a8KfwKny88mpZ6WyNeHQJC6qje";
    const tokenURIOther = "https://ipfs.io/ipfs/QmTM6pgQRbdJ7kfk1UYQDJE6g95Z2pc7g1Sb5rE1GY4JdN";

    const userDefinePrice = ethers.BigNumber.from(0);
    const userDefinePrice1 = ethers.BigNumber.from(1000);

    const appraisalPrice = ethers.BigNumber.from(0);
    const appraisalPrice1 = ethers.BigNumber.from(3500);

    beforeEach(async () => {
      await deploy();
      await unpause();
    });

    it("2.0 Should mint NFT to user", async function () {
      const consummer = await transcaAssetNFTContract.connect(owner).setAggregator(aggregatorProxyXAU);
      await consummer.wait();

      // [MintNFT]
      const nft = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
      await nft.wait();
      const ownerOf = await transcaAssetNFTContract.ownerOf(0);
      console.log("7s200:owner-of-0:before", ownerOf);

      const nft1 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeDIAMOND, indentifierCode, tokenURIDiamond, userDefinePrice, appraisalPrice1);
      await nft1.wait();
      const ownerOf1 = await transcaAssetNFTContract.ownerOf(1);
      console.log("7s200:owner-of-1:before", ownerOf1);

      const nft2 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURIOther, userDefinePrice1, appraisalPrice);
      await nft2.wait();
      const nft3 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURIOther, userDefinePrice1, appraisalPrice);
      await nft3.wait();
      const ownerOf3 = await transcaAssetNFTContract.ownerOf(1);
      console.log("7s200:owner-of-3:before", ownerOf3);

      // [Borrow - Request]
      const nftId = 0;
      const _inLoanAmount = ethers.utils.parseUnits("50", 18);
      const _inInterateRateAmount = ethers.utils.parseUnits("10", 18);
      const _inDuration = 100_000;

      const borrowRequest = await transcaBorrowContract.connect(owner).createBorrowAsset(nftId, false, _inLoanAmount, _inInterateRateAmount, _inDuration);
      await borrowRequest.wait();
      const ownerOf0AferCreateBorrowReq = await transcaAssetNFTContract.ownerOf(0);
      console.log("7s200:owner-of-0:before", ownerOf0AferCreateBorrowReq);

      const allBorrowReq = await transcaBorrowContract.getAllBorrowsRequest();
      console.log("7s200:allBorrow", allBorrowReq);

      // [Balance-of]
      await transcaToken.connect(owner).transfer(addr1.address, ethers.utils.parseUnits("500000", 18));
      await transcaToken.connect(owner).transfer(addr2.address, ethers.utils.parseUnits("100000", 18));

      await transcaToken.connect(owner).approve(transcaBorrowContract.address, ethers.utils.parseUnits("10000", 18), { from: owner.address });
      await transcaToken.connect(addr1).approve(transcaBorrowContract.address, ethers.utils.parseUnits("10000", 18), { from: addr1.address });
      await transcaToken.connect(addr2).approve(transcaBorrowContract.address, ethers.utils.parseUnits("10000", 18), { from: addr2.address });

      // [User 1,2 create lend offer req]
      const user1BalanceBeforeCreateReq = await transcaToken.balanceOf(addr1.address);
      console.log("7s200:user1BalanceBeforeCreateReq:", user1BalanceBeforeCreateReq);
      const user2BalanceBeforeCreateReq = await transcaToken.balanceOf(addr2.address);
      console.log("7s200:user2BalanceBeforeCreateReq:", user2BalanceBeforeCreateReq);
      const smcBalanceBeforeCreatereq = await transcaToken.balanceOf(transcaBorrowContract.address);
      console.log("7s200:balance:1", smcBalanceBeforeCreatereq);

      const user1LendReq = await transcaBorrowContract
        .connect(addr1)
        .createLendOfferForBorrowReq(allBorrowReq[0]._borrowReqId, ethers.utils.parseUnits("45", 18), ethers.utils.parseUnits("5", 18), _inDuration);
      await user1LendReq.wait();
      const user2LendReq = await transcaBorrowContract
        .connect(addr2)
        .createLendOfferForBorrowReq(allBorrowReq[0]._borrowReqId, ethers.utils.parseUnits("30", 18), ethers.utils.parseUnits("4", 18), _inDuration);
      await user2LendReq.wait();

      const allLenderByBorrowReq = await transcaBorrowContract.getAllLendReqByNFTId(allBorrowReq[0]._borrowReqId);
      console.log("7s200:allLenderByBorrowReq", allLenderByBorrowReq);

      const user1BalanceAfterCreateReq = await transcaToken.balanceOf(addr1.address);
      console.log("7s200:user1BalanceAfterCreateReq", user1BalanceAfterCreateReq);
      const user2BalanceAfterCreateReq = await transcaToken.balanceOf(addr2.address);
      console.log("7s200:user1BalanceAfterCreateReq", user2BalanceAfterCreateReq);
      const balanceOfSMCAfterCreateReq = await transcaToken.balanceOf(transcaBorrowContract.address);
      console.log("7s200:balanceOfSMCAfterCreateReq", balanceOfSMCAfterCreateReq);

      // [Mint bundle]
      // const mintBundle = await transcaBundleNFTContract.deposit([0, 1]);
      // console.log("7s200:bundle", mintBundle);
      // const mintwait = await mintBundle.wait();
      // console.log("7s200:mintwait", mintwait);

      // const ownerOf2 = await transcaAssetNFTContract.ownerOf(0);
      // console.log("7s200:owner-of-0:after", ownerOf2);
      // const ownerOf3 = await transcaAssetNFTContract.ownerOf(1);
      // console.log("7s200:owner-of-1:after", ownerOf3);

      // const bundleDetail = await transcaBundleNFTContract.getBundle(0);
      // console.log("7s200:bundleDetail", bundleDetail);
      // const ownerOfbundleAfterMint = await transcaBundleNFTContract.getOwner(0);
      // console.log("7s200:owner-bundle-after-mint", ownerOfbundleAfterMint);

      // const allbundle = await transcaBundleNFTContract.getAllBunelByOwner(owner.address);
      // console.log("7s200:allBundle", allbundle);

      // [Withdraw NFTs on bundle by bundle id]
      // const withdraw = await transcaBundleNFTContract.withdraw(0);
      // console.log("7s200:bundle:withdraw", withdraw);

      // const ownerOf4 = await transcaAssetNFTContract.ownerOf(0);
      // console.log("7s200:owner-of-0:withdraw", ownerOf4);
      // const ownerOf5 = await transcaAssetNFTContract.ownerOf(1);
      // console.log("7s200:owner-of-1:withdraw", ownerOf5);
      // const bundleDetail2 = await transcaBundleNFTContract.getBundle(0);
      // console.log("7s200:bundleDetail", bundleDetail2);
      // const ownerOfbundleAfterWithdraw = await transcaBundleNFTContract.getOwner(0);
      // console.log("7s200:owner-bundle-after", ownerOfbundleAfterWithdraw);

      // [Ignore]
      // const bundle = await transcaBundleNFTContract.getAssetAttribute(0);
      // console.log("7s200:bundle", bundle);
      // const asset = await transcaAssetNFTContract.getAllAssetByUser(owner.address);
      // console.log("7s200:asset", asset);

      // const nfts = await transcaAssetNFTContract.getAllAssetByUser(owner);
      // const nfts2 = await transcaAssetNFTContract.getAllAssetByUser(addr1);
      // console.log("7s200:nfts:1", nfts);
      // console.log("7s200:nfts:2", nfts2);
    });
  });
});
