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
      │     usdtSimulator     │ '0x1Ec7634F8906dD52EF536FC70E9BF49cD4F85604' │
      │    transcaAssetNFT    │ '0xC5bBb1C2010ca4a8F1afce5606e7478dFdc958D4' │
      │   transcaBundleNFT    │ '0x731f45cf007D8d7375F27Eac68e3a531e01ce442' │
      │ transcaIntermediation │ '0x6dc4204f5aBEebB853D1947d7f1080b910BB55fF' │
      └───────────────────────┴──────────────────────────────────────────────┘
    */

    const transcaAssetNFT = TranscaAssetNFT.attach("0xC5bBb1C2010ca4a8F1afce5606e7478dFdc958D4");
    const transcaBundleNFT = TranscaBundleNFT.attach("0x731f45cf007D8d7375F27Eac68e3a531e01ce442");
    const transcaIntermediation = TranscaIntermediation.attach("0x6dc4204f5aBEebB853D1947d7f1080b910BB55fF");
    const usdtSimulator = USDTSimulator.attach("0x1Ec7634F8906dD52EF536FC70E9BF49cD4F85604");

    const tx = await transcaAssetNFT.connect(owner).safeMint(addr1.address, weight, expireTime, assetTypeGOLD, indentifierCode, tokenURI, userDefinePrice, appraisalPrice);
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
