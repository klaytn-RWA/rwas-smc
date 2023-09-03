import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers, upgrades } from "hardhat";

describe("Transca Vault assests", function () {
  // Contracts:
  let transcaAssetNFTContract: Contract;

  // Address:
  let owner: SignerWithAddress, addr1: SignerWithAddress;

  // Variable:
  const aggregatorProxy = "0x4b0687ce6ec3fe6c019467c744d0c563643bdfa4"; // BTC-USDT
  const aggregatorProxyXAU = "0x555E072996d0335Ec63B448ddD507CB99379C723";

  const deploy = async () => {
    [owner, addr1] = await ethers.getSigners();

    // Deploy
    const transcaAssetNFTContractFactory = await ethers.getContractFactory("TranscaAssetNFT");
    const deployTranscaAssetNFT = await upgrades.deployProxy(transcaAssetNFTContractFactory);
    transcaAssetNFTContract = await deployTranscaAssetNFT.deployed();
    // console.log("-> 7s200:contract:", transcaAssetNFTContract.address);
    // console.log("-> 7s200:owner:", owner.address);
    // console.log("-> 7s200:addr1:", addr1.address);
  };

  // const setSpec = async () => {
  //   // await expect(transcaAssetNFTContract.connect(owner).setSpec()).to.not.reverted;
  //   // await expect(transcaAssetNFTContract.connect(addr1).setSpec()).to.be.reverted;

  //   const s1 = await transcaAssetNFTContract.connect(owner).setSpec();
  //   const s1wait = await s1.wait();
  //   console.log("-> 0-setSpec:", s1wait);
  // };

  const unpause = async () => {
    // await expect(transcaAssetNFTContract.connect(owner).unpause()).to.not.reverted;
    // await expect(transcaAssetNFTContract.connect(addr1).unpause()).to.be.reverted;

    const u1 = await transcaAssetNFTContract.connect(owner).unpause();
    const u1wait = await u1.wait();
    // console.log("-> 0-unpause:", u1wait);
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
      // await setSpec();
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
      console.log("-> 1.2-consummer:", consummerWait);

      const nft = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
      await nft.wait();

      console.log("7s2001");
      const nft1 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeDIAMOND, indentifierCode, tokenURI, userDefinePrice1, appraisalPrice);
      await nft1.wait();

      console.log("7s2002");
      const nft2 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(owner.address, weight, expireTime, assetTypeOTHER, indentifierCode, tokenURI, userDefinePrice1, appraisalPrice);
      await nft2.wait();

      console.log("7s2003");
      const nft3 = await transcaAssetNFTContract
        .connect(owner)
        .safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
      await nft3.wait();

      // const nftWait = await nft.wait();
      // console.log("-> 1.2-nft", nftWait);

      const nfts = await transcaAssetNFTContract.connect(owner).getAllAssetByUser();
      const nfts2 = await transcaAssetNFTContract.connect(addr1).getAllAssetByUser();
      console.log("7s200:nfts:1", nfts);
      console.log("7s200:nfts:2", nfts2);
      // const nftDetail = await transcaAssetNFTContract.getAssetDetail(0);
      // console.log("-> 1.2-nft-detail", nftDetail);
    });
  });
});
