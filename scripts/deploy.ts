import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import "@openzeppelin/hardhat-upgrades";
import { Contract } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main() {
  let transcaAssetNFT: Contract;
  let transcaBundleNFT: Contract;
  let transcaIntermediation: Contract;
  let usdtSimulator: Contract;

  let owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress;

  const deploy = async (showConsole: boolean = true) => {
    [owner, addr1, addr2] = await ethers.getSigners();

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

    if (showConsole) {
      console.table({
        usdtSimulator: usdtSimulator.address,
        transcaAssetNFT: transcaAssetNFT.address,
        transcaBundleNFT: transcaBundleNFT.address,
        transcaIntermediation: transcaIntermediation.address,
      });
    }
  };

  const setSpec = async () => {
    await (await transcaBundleNFT.connect(owner).setAsset(transcaAssetNFT.address)).wait();
    await (await transcaIntermediation.connect(owner).setAsset(transcaAssetNFT.address)).wait();
    await (await transcaIntermediation.connect(owner).setBundle(transcaBundleNFT.address)).wait();
    await (await transcaIntermediation.connect(owner).setToken(usdtSimulator.address)).wait();
  };

  const unpauseAll = async () => {
    await (await transcaAssetNFT.connect(owner).unpause()).wait();
    await (await transcaBundleNFT.connect(owner).unpause()).wait();
    await (await transcaIntermediation.connect(owner).unpause()).wait();
  };

  await deploy();
  await setSpec();
  await unpauseAll();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
