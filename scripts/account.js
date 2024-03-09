const { ethers } = require("ethers");

const privateKey1 = "0xce2769eb44a97aadf7e3f42dafdcdb2a7f8cb23cdddc1403ff3df3ed5349263b";
const privateKey2 = "0x47f4362c7a378cb8be3a8a48e910999b12360315e956cfdde2361a9ee67dbf0f";
const privateKey3 = "0x9b8602ee04df094962cd0128e5827ae6cc2f8acec02289e6833060368b14e4c0";
const wallet1 = new ethers.Wallet(privateKey1);
const address1 = wallet1.address;


const wallet2 = new ethers.Wallet(privateKey2);
const address2 = wallet2.address;

const wallet3 = new ethers.Wallet(privateKey3);
const address3 = wallet3.address;

console.log("Key Pair 1");
console.log("Private Key:",privateKey1);
console.log("wallet:", wallet1);
console.log("Address:", address1);

console.log("Key Pair 2");
console.log("Private Key:",privateKey2);
console.log("wallet:", wallet2);
console.log("Address:", address2);

console.log("Key Pair 3");
console.log("Private Key:", privateKey3);
console.log("wallet:", wallet3);
console.log("Address:", address3);
