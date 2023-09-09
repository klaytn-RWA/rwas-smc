import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";

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

async function main() {
  const [owner, addr1, addr2] = await ethers.getSigners();

  const mint = async (showConsole: boolean = true) => {
    const USDTSimulator = await ethers.getContractFactory("USDTSimulator");
    const TranscaAssetNFT = await ethers.getContractFactory("TranscaAssetNFT");
    const TranscaBundleNFT = await ethers.getContractFactory("TranscaBundleNFT");
    const TranscaIntermediation = await ethers.getContractFactory("TranscaIntermediation");

    /*
┌───────────────────────┬──────────────────────────────────────────────┐
│        (index)        │                    Values                    │
├───────────────────────┼──────────────────────────────────────────────┤
│    transcaAssetNFT    │ '0x3419c63ebf27752ae3D6175133ed63b1e042D489' │
│   transcaBundleNFT    │ '0x6b3E721e9081dE6486F7fFe5C9f2149BF8DDfEdA' │
│ transcaIntermediation │ '0x1174d4A124A765c94da041DFe7A3f9F9D9Da67A7' │
│     usdtSimulator     │ '0xD900648B31DB7550f2833D4b3e5722ce6Ee8CAeC' │
└───────────────────────┴──────────────────────────────────────────────┘
    */

    const transcaIntermediation = TranscaIntermediation.attach("0x2714577F0F5468187084023a91a5d936Ae1A9BA2");
    const usdtSimulator = USDTSimulator.attach("0xb46e565D67E2eB90257380009C78883fC944b71e");

    const tx = await usdtSimulator.connect(owner).transfer(transcaIntermediation.address, ethers.utils.parseUnits("100000000", 18));
    await tx.wait();
  };

  await mint();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
