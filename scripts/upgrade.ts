// Copyright 2023 Transflox LLC. All rights reserved.

import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";

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

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account balance:", (await owner.getBalance()).toString());

  // const TranscaAssetNFT = await ethers.getContractFactory("TranscaAssetNFT");
  const TranscaIntermediation = await ethers.getContractFactory("TranscaIntermediation");

  // await upgrades.upgradeProxy("0xff91de6A3BA6d43729F76116188ED28013d3199C", TranscaAssetNFT);
  const contract = await upgrades.upgradeProxy("0x8270991e4e36FA07469C0753F9362755ADE0B58b", TranscaIntermediation);
  console.log(contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
