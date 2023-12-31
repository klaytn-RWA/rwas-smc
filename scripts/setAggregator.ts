import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";

const aggregatorProxyXAU = "0x555E072996d0335Ec63B448ddD507CB99379C723";

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
│    transcaAssetNFT    │ '0x1Faaba3A953B4ed52747eB20655a7a8a9771b5DD' │
│   transcaBundleNFT    │ '0x49D7A8b6656A6252DBf9AD88E1aE7fee93f6a9dD' │
│ transcaIntermediation │ '0x2714577F0F5468187084023a91a5d936Ae1A9BA2' │
│     usdtSimulator     │ '0xb46e565D67E2eB90257380009C78883fC944b71e' │
└───────────────────────┴──────────────────────────────────────────────┘
    */

    const transcaAssetNFT = TranscaAssetNFT.attach("0x1Faaba3A953B4ed52747eB20655a7a8a9771b5DD");

    //
    const tx = await transcaAssetNFT.connect(owner).setAggregator(aggregatorProxyXAU);
    await tx.wait();

    console.log(tx.hash);
  };

  await mint();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
