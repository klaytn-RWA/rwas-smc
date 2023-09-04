import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import BN from "bn.js";
import { expect } from "chai";
import abi from "ethereumjs-abi";
import { Contract } from "ethers";
import { ethers, upgrades } from "hardhat";

describe("Transca Vault assests", function () {
  // Contracts:
  let transcaAssetNFTContract: Contract;
  let transcaBundleNFTContract: Contract;

  // Address:
  let owner: SignerWithAddress, addr1: SignerWithAddress;

  // Variable:
  const aggregatorProxyXAU = "0x555E072996d0335Ec63B448ddD507CB99379C723";

  const deploy = async () => {
    [owner, addr1] = await ethers.getSigners();

    // Deploy
    const transcaAssetNFTContractFactory = await ethers.getContractFactory("TranscaAssetNFT");
    const deployTranscaAssetNFT = await upgrades.deployProxy(transcaAssetNFTContractFactory);
    transcaAssetNFTContract = await deployTranscaAssetNFT.deployed();

    const transcaBundleNFTContractFactory = await ethers.getContractFactory("TranscaBundleNFT");
    const deployTranscaBundleNFT = await upgrades.deployProxy(transcaBundleNFTContractFactory);
    transcaBundleNFTContract = await deployTranscaBundleNFT.deployed();
    console.log("7s200:bundle:contract", transcaBundleNFTContract.address);

    const setcontract = await transcaBundleNFTContract.setAddress(transcaAssetNFTContract.address);
    await setcontract.wait();
  };

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
    const userDefinePrice = ethers.BigNumber.from(0);
    const userDefinePrice1 = ethers.BigNumber.from(1000);
    const appraisalPrice = ethers.BigNumber.from(0);

    beforeEach(async () => {
      await deploy();
      await unpause();
    });

    // describe("1.0 - pause can't mint NFT", function () {
    //   beforeEach(async () => {
    //     await pause();
    //   });
    //   it("1.0.1 - user can't mint NFT", async function () {
    //     await expect(transcaAssetNFTContract.connect(addr1).safeMint(addr1.address, weight, expireTime, assetType, indentifierCode)).to.be.reverted;
    //   });
    //   it("1.0.1 - owner can't mint NFT", async function () {
    //     await expect(transcaAssetNFTContract.connect(owner).safeMint(addr1.address, weight, expireTime, assetType, indentifierCode)).to.be.reverted;
    //   });
    // });

    // it("1.1 - unpause can mint NFT", async function () {
    //   await expect(transcaAssetNFTContract.connect(owner).safeMint(addr1.address, weight, expireTime, assetType, indentifierCode)).to.be.not.reverted;
    // });

    // it("1.2 - use can't mint NFT", async function () {
    //   await expect(transcaAssetNFTContract.connect(addr1).safeMint(addr1.address, weight, expireTime, assetType, indentifierCode)).to.be.reverted;
    // });

    // it("1.3 - owner can mint NFT", async () => {
    //   await expect(transcaAssetNFTContract.connect(owner).safeMint(addr1.address, weight, expireTime, assetType, indentifierCode)).to.be.not.reverted;
    // });

    it("2.0 Should mint NFT to user", async function () {
      const consummer = await transcaAssetNFTContract.connect(owner).setAggregator(aggregatorProxyXAU);
      const consummerWait = await consummer.wait();
      // console.log("-> 1.2-consummer:", consummerWait);
      const nft = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
      await nft.wait();
      console.log("7s2001");
      const ownerOf = await transcaAssetNFTContract.ownerOf(0);
      console.log("7s200:owner-of-0", ownerOf);

      const nft1 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeDIAMOND, indentifierCode, tokenURI, userDefinePrice1, appraisalPrice);
      await nft1.wait();
      console.log("7s2002");
      const ownerOf1 = await transcaAssetNFTContract.ownerOf(1);
      console.log("7s200:owner-of-1", ownerOf1);
      // const nft2 = await transcaAssetNFTContract
      //   .connect(owner)
      //   .safeMint(owner.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURI, userDefinePrice1, appraisalPrice);
      // await nft2.wait();
      // console.log("7s2003");
      // const nft3 = await transcaAssetNFTContract
      //   .connect(owner)
      //   .safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
      // await nft3.wait();
      const hash = abi.soliditySHA3(["address", "uint256[]"], [new BN(owner.address.slice(2), 16), [new BN(0, 10), new BN(1, 10)]]);
      console.log("7s200:hash", hash);

      const signature = await owner.signMessage(hash);
      console.log("7s200:sig", signature);

      const mintBundle = await transcaBundleNFTContract.deposit([0, 1], signature);
      console.log("7s200:bundle", mintBundle);
      const mintwait = await mintBundle.wait();
      console.log("7s200:mintwait", mintwait);

      const ownerOf2 = await transcaAssetNFTContract.ownerOf(0);
      console.log("7s200:owner-of-0", ownerOf2);
      const ownerOf3 = await transcaAssetNFTContract.ownerOf(1);
      console.log("7s200:owner-of-1", ownerOf3);

      const bundleDetail = await transcaBundleNFTContract.getBundle(0);
      console.log("7s200:bundleDetail", bundleDetail);

      // const bundle = await transcaBundleNFTContract.getAssetAttribute(0);
      // console.log("7s200:bundle", bundle);

      // const nfts = await transcaAssetNFTContract.getAllAssetByUser(owner);
      // const nfts2 = await transcaAssetNFTContract.getAllAssetByUser(addr1);
      // console.log("7s200:nfts:1", nfts);
      // console.log("7s200:nfts:2", nfts2);
    });
  });
});
