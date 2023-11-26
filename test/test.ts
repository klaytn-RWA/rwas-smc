import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers, upgrades } from "hardhat";

const aggregatorProxyXAU = "0x555E072996d0335Ec63B448ddD507CB99379C723";

const weight = ethers.utils.parseUnits("1", 18);

const now = new Date().getTime();
const expire = now + 1_000_000;
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

describe("Transca Vault assests", function () {
  let transcaAssetNFT: Contract;
  let transcaBundleNFT: Contract;
  let transcaIntermediation: Contract;
  let usdtSimulator: Contract;
  let lottery: Contract;

  let owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress;

  const deploy = async (showConsole: boolean = true) => {
    [owner, addr1, addr2, user1, user2] = await ethers.getSigners();

    const USDTSimulator = await ethers.getContractFactory("USDTSimulator");
    usdtSimulator = await (await USDTSimulator.deploy("USDT", "USDT")).deployed();

    const TranscaAssetNFT = await ethers.getContractFactory("TranscaAssetNFT");
    const deployTranscaAssetNFT = await upgrades.deployProxy(TranscaAssetNFT);
    transcaAssetNFT = await deployTranscaAssetNFT.deployed();

    const TranscaBundleNFT = await ethers.getContractFactory("TranscaBundleNFT");
    const deployTranscaBundleNFT = await upgrades.deployProxy(TranscaBundleNFT);
    transcaBundleNFT = await deployTranscaBundleNFT.deployed();

    const TranscaIntermediation = await ethers.getContractFactory("TranscaIntermediation");
    const deployTranscaIntermediation = await upgrades.deployProxy(TranscaIntermediation);
    transcaIntermediation = await deployTranscaIntermediation.deployed();

    const Lottery = await ethers.getContractFactory("Lottery");
    const deployLottery = await upgrades.deployProxy(Lottery);
    lottery = await deployLottery.deployed();

    if (showConsole) {
      console.table({
        usdtSimulator: usdtSimulator.address,
        transcaAssetNFT: transcaAssetNFT.address,
        transcaBundleNFT: transcaBundleNFT.address,
        transcaIntermediation: transcaIntermediation.address,
        lottery: lottery.address,
      });
    }
  };

  const setSpec = async () => {
    await expect(await transcaAssetNFT.connect(owner).setOwnerMultiSign(owner.address, addr1.address, addr2.address)).to.not.reverted;
    await expect(await transcaBundleNFT.connect(owner).setAsset(transcaAssetNFT.address)).to.not.reverted;
    await expect(await transcaIntermediation.connect(owner).setAsset(transcaAssetNFT.address)).to.not.reverted;
    await expect(await transcaIntermediation.connect(owner).setBundle(transcaBundleNFT.address)).to.not.reverted;
    await expect(await transcaIntermediation.connect(owner).setToken(usdtSimulator.address)).to.not.reverted;
    await expect(await lottery.connect(owner).setAsset(transcaAssetNFT.address)).to.not.reverted;
    await expect(await lottery.connect(owner).setToken(usdtSimulator.address)).to.not.reverted;
  };

  const unpauseAll = async () => {
    await expect(await transcaAssetNFT.connect(owner).unpause()).to.not.reverted;
    await expect(await transcaBundleNFT.connect(owner).unpause()).to.not.reverted;
    await expect(await transcaIntermediation.connect(owner).unpause()).to.not.reverted;
    await expect(await lottery.connect(owner).unpause()).to.not.reverted;
  };

  const transferUsdtToUser = async () => {
    // await expect(usdtSimulator.connect(owner).transfer(addr1.address, ethers.utils.parseUnits("5000000", 18))).to.not.reverted;
    await expect(await (await usdtSimulator.connect(owner).transfer(addr2.address, ethers.utils.parseUnits("5000000", 18))).wait()).to.not.reverted;
  };

  const getAll = async () => {
    console.table({
      transca_paused: await transcaAssetNFT.paused(),
    });
  };

  // const reset = async () => {
  //   await ethers.provider.send("hardhat_reset", []);
  // };

  const setAggregator = async () => {
    await expect(await (await transcaAssetNFT.connect(owner).setAggregator(aggregatorProxyXAU)).wait()).to.not.reverted;
  };

  const mintManyNFTs = async () => {
    await expect(
      await (await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).wait(),
    ).to.not.reverted;
    await expect(
      await (
        await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeDIAMOND, indentifierCode, tokenURIDiamond, userDefinePrice, appraisalPrice1)
      ).wait(),
    ).to.not.reverted;
    await expect(
      await (
        await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURIOther, userDefinePrice1, appraisalPrice)
      ).wait(),
    ).to.not.reverted;
    await expect(
      await (
        await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURIOther, userDefinePrice1, appraisalPrice)
      ).wait(),
    ).to.not.reverted;
    await expect(
      await (
        await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURIOther, userDefinePrice1, appraisalPrice)
      ).wait(),
    ).to.not.reverted;
  };

  describe("Tests", function () {
    beforeEach(async () => {
      await deploy(true);
      await setSpec();
      await unpauseAll();
      await transferUsdtToUser();
      await getAll();
    });

    it("can create mint request", async () => {
      await expect(transcaAssetNFT.connect(user1).requestMintRWA(weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).to.not.reverted;
      await expect(transcaAssetNFT.connect(owner).executeMint(0)).to.reverted;
      await expect(transcaAssetNFT.connect(addr2).confirmTransaction(0)).to.not.reverted; // stocker sign
      await expect(transcaAssetNFT.connect(addr1).confirmTransaction(0)).to.not.reverted; // audit sign
      await expect(await transcaAssetNFT.balanceOf(user1.address)).to.not.equal(1);
      await expect(transcaAssetNFT.connect(owner).executeMint(0)).to.reverted;
      await expect(transcaAssetNFT.connect(owner).confirmTransaction(0)).to.not.reverted; // transca sign
      await expect(transcaAssetNFT.connect(owner).executeMint(0)).to.not.reverted; // execute transcation
      await expect(await transcaAssetNFT.balanceOf(user1.address)).to.equal(1);
    });

    it("can create lottery session", async () => {
      await expect(transcaAssetNFT.connect(owner).safeMint(owner.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).to.not
        .reverted;

      await expect(transcaAssetNFT.connect(addr1).setApprovalForAll(lottery.address, true)).to.not.reverted;
      await expect(lottery.connect(addr1).createLottery(0, 100000)).to.reverted;

      await expect(transcaAssetNFT.connect(owner).setApprovalForAll(lottery.address, true)).to.not.reverted;
      await expect(lottery.connect(owner).createLottery(0, 100000)).to.not.reverted; //1000 ms

      // approve - buy slot - 1
      await expect(usdtSimulator.connect(addr2).approve(lottery.address, ethers.utils.parseUnits("1", 0))).to.not.reverted;
      await expect(lottery.connect(addr2).buySlot(0, 1, 1)).to.not.reverted;

      // approve - buy slot - 2
      await expect(usdtSimulator.connect(addr2).approve(lottery.address, ethers.utils.parseUnits("1", 0))).to.not.reverted;
      await expect(lottery.connect(addr2).buySlot(0, 2, 1)).to.not.reverted;

      await expect(lottery.connect(owner).updateWinNumber(2, 0)).to.not.reverted;

      // const a = await lottery.getLottery(0);
      // console.log("7s200:lottery:id", a);
      // const c = await lottery.getLotteryBuyers(0);
      // console.log("7s200:lottery:buyers", c);
    });

    it("can mint normal NFT", async () => {
      await mintManyNFTs();
    });

    it.skip("can mint NFT on network", async () => {
      await setAggregator();

      await expect(transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).to.not
        .reverted;
    });

    it("can create borrow with NFT", async () => {
      await expect(transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).to.not
        .reverted;
      await expect(transcaAssetNFT.connect(addr1).setApprovalForAll(transcaIntermediation.address, true)).to.not.reverted;
      await expect(transcaIntermediation.connect(addr1).createBorrow(0, transcaAssetNFT.address, 1, 1, 10)).to.not.reverted;
    });

    it("can direct lend", async () => {
      await expect(transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice)).to.not
        .reverted;
      await expect(transcaAssetNFT.connect(addr1).setApprovalForAll(transcaIntermediation.address, true)).to.not.reverted;

      await expect(transcaIntermediation.connect(addr1).createBorrow(0, transcaAssetNFT.address, 5, 5, 10)).to.not.reverted;
      expect(await transcaAssetNFT.ownerOf(0)).to.eq(transcaIntermediation.address);

      expect(await usdtSimulator.balanceOf(addr2.address)).to.eq(ethers.utils.parseUnits("5000000", 18));

      await expect(usdtSimulator.connect(addr2).approve(transcaIntermediation.address, ethers.utils.parseUnits("1", 0))).to.not.reverted;
      await expect(transcaIntermediation.connect(addr2).createLendOffer(0, 5)).to.revertedWith("ERC20: insufficient allowance");

      await expect(usdtSimulator.connect(addr2).approve(transcaIntermediation.address, ethers.utils.parseUnits("5", 0))).to.not.reverted;
      await expect(transcaIntermediation.connect(addr2).createLendOffer(0, 5)).to.not.reverted;

      expect(await usdtSimulator.balanceOf(addr1.address)).to.eq(ethers.BigNumber.from(5));
    });

    it("can handle bundle", async () => {
      await mintManyNFTs();

      await expect(transcaAssetNFT.connect(addr1).setApprovalForAll(transcaBundleNFT.address, true)).to.not.reverted;
      await expect(transcaBundleNFT.connect(addr1).deposit([0, 1])).to.not.reverted;

      expect(await transcaAssetNFT.balanceOf(transcaBundleNFT.address)).to.eq(ethers.BigNumber.from(2));
      expect(await transcaBundleNFT.balanceOf(addr1.address)).to.eq(ethers.BigNumber.from(1));

      expect(JSON.stringify(await transcaBundleNFT.getAllBundleByOwner(addr1.address))).to.eq(
        '[[{"type":"BigNumber","hex":"0x00"},[{"type":"BigNumber","hex":"0x00"},{"type":"BigNumber","hex":"0x01"}]]]',
      );

      await expect(transcaBundleNFT.connect(addr1).withdraw(0)).to.not.reverted;
      expect(await transcaAssetNFT.balanceOf(transcaBundleNFT.address)).to.eq(ethers.BigNumber.from(0));
      expect(await transcaBundleNFT.balanceOf(addr1.address)).to.eq(ethers.BigNumber.from(0));
    });

    it.skip("Should mint NFT to user", async function () {
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
