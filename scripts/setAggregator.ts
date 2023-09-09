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
