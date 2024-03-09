const hre = require("hardhat");
const { ethers } = require("ethers");

async function main() {
  //部署MyNFT合约
  const MyNFT = await hre.ethers.getContractFactory("MyNFT");
  const myNFT = await MyNFT.deploy();
  //部署NFTExchange合约
  const NFTExchange = await hre.ethers.getContractFactory("NFTExchange");
  const nftExchange = await NFTExchange.deploy(myNFT.address);
  //部署NFTVote合约
  const NFTVote = await hre.ethers.getContractFactory("NFTVote");
  const nftVote = await NFTVote.deploy(nftExchange.address, myNFT.address);
  //部署VotingForSelling合约
  const VotingForSelling = await hre.ethers.getContractFactory("VotingForSelling");
  const votingForSelling = await VotingForSelling.deploy(nftVote.address);


  console.log("MyNFT deployed to:", myNFT.address);
  console.log("NFTExchange deployed to:", nftExchange.address);
  console.log("NFTVote deployed to:", nftVote.address);
  console.log("VotingForSelling deployed to:", votingForSelling.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
