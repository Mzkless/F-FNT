require("@nomicfoundation/hardhat-toolbox");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const { ethers } = require("ethers");
const privateKey1 = "0xce2769eb44a97aadf7e3f42dafdcdb2a7f8cb23cdddc1403ff3df3ed5349263b";
const privateKey2 = "0x47f4362c7a378cb8be3a8a48e910999b12360315e956cfdde2361a9ee67dbf0f";
const privateKey3 = "0x9b8602ee04df094962cd0128e5827ae6cc2f8acec02289e6833060368b14e4c0";

module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      accounts: [
        { privateKey: privateKey1, balance: "10000000000000000000000" },
        { privateKey: privateKey2, balance: "10000000000000000000000" },
        { privateKey: privateKey3, balance: "10000000000000000000000" },
      ],
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

