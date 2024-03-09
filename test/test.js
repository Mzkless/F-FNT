const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;



describe("NFT切分募集购买", function () {
  let myNFT;
  let nftExchange;
  let nftVote;
  let orderBookExchange;
  let owner;
  let account1;
  let account2;


  beforeEach(async function () {
    console.log("部署脚本");
    //部署MyNFT合约
    const MyNFT = await ethers.getContractFactory("MyNFT");
    myNFT = await MyNFT.deploy();
    await myNFT.deployed();
    console.log("MyNFT deployed to:", myNFT.address);
    //部署NFTExchange合约
    const NFTExchange = await ethers.getContractFactory("NFTExchange");
    nftExchange = await NFTExchange.deploy(myNFT.address);
    await nftExchange.deployed();
    console.log("NFTExchange deployed to:", nftExchange.address);
    // //部署OrderBookExchange合约
    // const OrderBookExchange = await ethers.getContractFactory("OrderBookExchange");
    // orderBookExchange = await OrderBookExchange.deploy();
    // await orderBookExchange.deployed();
    // console.log("OrderBookExchange deployed to:", orderBookExchange.address);
    // console.log("");
    //部署NFTVote合约
    const NFTVote = await ethers.getContractFactory("NFTVote");
    nftVote = await NFTVote.deploy(nftExchange.address, myNFT.address);
    await nftVote.deployed();
    console.log("NFTVote deployed to:", nftVote.address);



    [owner, account1, account2] = await ethers.getSigners();
    console.log("初始化三个账户:owner,account1,account2");
    console.log("owner:", owner.address);
    console.log("account1:", account1.address);
    console.log("account2:", account2.address);
    console.log();

  });

  it("NFT创建", async function () {

    // 调用 createNFT 函数给 owner 生成一个 NFT
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);

    //断言：检查是否是owner生成了NFT
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);

    //打印owner地址
    console.log("owner:", _ownerOf);
    console.log("NFT创建成功")
    console.log();

  });

  it("NFT授权", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);

    //断言：检查是否是owner生成了NFT
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    // 调用NFTExchange合约中uploadNFT函数上传NFT至NFTExchange交易合约.
    await myNFT.connect(owner).approve(nftExchange.address, 1);

    //断言是否授权成功
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);

    //打印"授权NFT成功"
    console.log("NFT授权成功");

  });

  it("NFT上传", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    await myNFT.connect(owner).approve(nftExchange.address, 1);
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);
    await nftExchange.connect(owner).uploadNFT(1, ethers.utils.parseEther("3"));

    //断言是否上传NFT成功
    const upNFT = await nftExchange.connect(owner).ownerOf(1);
    expect(upNFT).to.equal(owner.address);
    console.log("上传NFT成功");

  });

  it("Vote创建", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    await myNFT.connect(owner).approve(nftExchange.address, 1);
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);
    await nftExchange.connect(owner).uploadNFT(1, ethers.utils.parseEther("3"));
    const upNFT = await nftExchange.connect(owner).ownerOf(1);
    expect(upNFT).to.equal(owner.address);
    await nftVote.connect(owner).createProposal(1, ethers.utils.parseEther("3"), 1688820894);

    //断言是否Vote创建成功
    vote = await nftVote.connect(owner).proposals(1);
    expect(vote.proposer).to.equal(owner.address);
    console.log("Vote创建成功");

  });

  it("NFT众筹", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    await myNFT.connect(owner).approve(nftExchange.address, 1);
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);
    await nftExchange.connect(owner).uploadNFT(1, ethers.utils.parseEther("3"));
    const upNFT = await nftExchange.connect(owner).ownerOf(1);
    expect(upNFT).to.equal(owner.address);
    await nftVote.connect(owner).createProposal(1, ethers.utils.parseEther("3"), 1688820894);
    //owner,account1向提案Vote发起转账，众筹购买NFT
    console.log("owner向Vote转入3ETH中");
    await nftVote.connect(owner).contribute(1, { value: ethers.utils.parseEther("2") });
    console.log("转入2ETH成功");
    console.log("account1向Vote转入1ETH中");
    await nftVote.connect(account1).contribute(1, { value: ethers.utils.parseEther("1") });
    console.log("转入1ETH成功");


    //断言是否众筹成功
    vote = await nftVote.connect(owner).proposals(1);
    expect(vote.closed).to.equal(true);
    expect(vote.currentAmount).to.equal(vote.targetAmount);
    console.log("NFT众筹成功");

  });
  it("Token代币分发", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    await myNFT.connect(owner).approve(nftExchange.address, 1);
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);
    await nftExchange.connect(owner).uploadNFT(1, ethers.utils.parseEther("3"));
    const upNFT = await nftExchange.connect(owner).ownerOf(1);
    expect(upNFT).to.equal(owner.address);
    await nftVote.connect(owner).createProposal(1, ethers.utils.parseEther("3"), 1688820894);
    await nftVote.connect(owner).contribute(1, { value: ethers.utils.parseEther("2") });
    await nftVote.connect(account1).contribute(1, { value: ethers.utils.parseEther("1") });
    vote = await nftVote.connect(owner).proposals(1);
    expect(vote.closed).to.equal(true);
    expect(vote.currentAmount).to.equal(vote.targetAmount);


    // 获取部署的 MyToken 合约实例
    const MyToken = await ethers.getContractFactory("MyToken");
    const myTokenAddress = await nftVote.getMyTokenAddress();
    const myTokenInstance = MyToken.attach(myTokenAddress);

    const tokenName = await myTokenInstance.name();
    const tokenSymbol = await myTokenInstance.symbol();
    const balance2 = await myTokenInstance.balanceOf(owner.address);
    const balance3 = await myTokenInstance.balanceOf(account1.address);
    console.log("代币名称:" + tokenName);
    console.log("代币符号:" + tokenSymbol);
    console.log("owener账户token代币余额:" + balance2.toString());
    console.log("account1账户token代币余额:" + balance3.toString());

  });
  it("Token代币挂单操作", async function () {
    const tokenURI = "https://example.com/nft";
    const tokenURIValue = ethers.utils.formatBytes32String(tokenURI);
    await myNFT.connect(owner).createNFT(owner.address, tokenURIValue);
    const _ownerOf = await myNFT.connect(owner).ownerOf(1);
    expect(_ownerOf).to.equal(owner.address);
    await myNFT.connect(owner).approve(nftExchange.address, 1);
    const app = await myNFT.connect(owner).getApproved(1);
    expect(app).to.equal(nftExchange.address);
    await nftExchange.connect(owner).uploadNFT(1, ethers.utils.parseEther("3"));
    const upNFT = await nftExchange.connect(owner).ownerOf(1);
    expect(upNFT).to.equal(owner.address);
    await nftVote.connect(owner).createProposal(1, ethers.utils.parseEther("3"), 1688820894);
    await nftVote.connect(owner).contribute(1, { value: ethers.utils.parseEther("2") });
    await nftVote.connect(account1).contribute(1, { value: ethers.utils.parseEther("1") });
    vote = await nftVote.connect(owner).proposals(1);
    expect(vote.closed).to.equal(true);
    expect(vote.currentAmount).to.equal(vote.targetAmount);
    const MyToken = await ethers.getContractFactory("MyToken");
    const myTokenAddress = await nftVote.getMyTokenAddress();
    const myTokenInstance = MyToken.attach(myTokenAddress);
    const tokenName = await myTokenInstance.name();
    const tokenSymbol = await myTokenInstance.symbol();
    const balance1 = await myTokenInstance.balanceOf(owner.address);
    const balance2 = await myTokenInstance.balanceOf(account1.address);
    console.log("owner交易以前代币余额:"+balance1.toString());
    console.log("account1交易以前代币余额:"+balance2.toString());
    console.log();
    //挂单操作


    const approvalAmount = ethers.utils.parseUnits("1000", "ether"); // 设置为你希望的授权额度

    // 授权给 OrderBookExchange 合约
    await myTokenInstance.connect(owner).approve(nftVote.address, approvalAmount);
    await myTokenInstance.connect(account1).approve(nftVote.address, approvalAmount);
    // 创建卖单和买单
    console.log("owner创建卖单:1000000000000000");
    console.log("account1创建买单:1000000000000000");
    console.log();
    await nftVote.connect(owner).createSellOrder(myTokenAddress, 1000000000000000, 1000);
    await nftVote.connect(account1).createBuyOrder(myTokenAddress, 1000000000000000, 1000);

    // 执行交易
    await nftVote.executeTrades(myTokenAddress);

    const balance3 = await myTokenInstance.balanceOf(owner.address);
    const balance4 = await myTokenInstance.balanceOf(account1.address);
    console.log("owner交易以后代币余额:"+balance3.toString());
    console.log("account1交易以后代币余额:"+balance4.toString());
    console.log();
    console.log("撮合交易成功");
    console.log();
  });
  console.log("测试完毕！")
});
