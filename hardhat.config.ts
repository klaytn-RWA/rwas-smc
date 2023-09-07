// Copyright 2021 - 2023 Transflox LLC. All rights reserved.

import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import dotenv from "dotenv";
import "hardhat-abi-exporter";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config({ path: __dirname + "/.env" });

const config: HardhatUserConfig = {
  // defaultNetwork: "baobab",

  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          evmVersion: "paris",
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 2_147_483_647,
  },
  networks: {
    baobab: {
      url: "https://api.baobab.klaytn.net:8651",
      timeout: 2_147_483_647,
      accounts: [process.env.PRIVATE_KEY!, process.env.PRIVATE_KEY_1!, process.env.PRIVATE_KEY_2!],
      gas: 5242880,
      gasPrice: 51640625000,
    },
    goerli: {
      url: "https://goerli-eth.w3node.com/af4e93a4f1e946ce101ec53912e4daf943759b8ac2b30f33c3b1f73ae4ba0414/api",
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 2_147_483_647,
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/DXrYz6Q2h-LGE_BZ3vO_rljEF7W4tO65",
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 11155111,
      timeout: 2_147_483_647,
    },
    ethereum: {
      url: "https://eth-mainnet.g.alchemy.com/v2/22gU7WLjJUMVrvia8yOmeU8MDanUuLdW",
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 2_147_483_647,
    },
    cross: {
      url: "https://rpc-kura.cross.technology",
      // "https://testnet.cvcscan.com"
      chainId: 5555,
      accounts: [process.env.PRIVATE_KEY!],
      allowUnlimitedContractSize: true,
      timeout: 2_147_483_647,
    },
  },
  abiExporter: {
    path: "abi",
    clear: true,
    flat: true,
    only: [],
    spacing: 2,
  },
};

export default config;
