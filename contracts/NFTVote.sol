// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFTExchange.sol";
import { NFTExchange } from "./NFTExchange.sol";
import { MyNFT } from "./MyNFT.sol";
import { MyToken } from "./MyToken.sol";
// import { OrderBookExchange } from "./OrderBookExchange.sol";

contract NFTVote{
    address public owner;
    NFTExchange private nftExchange;
    MyNFT private myNFT;
    MyToken public myToken;
    // OrderBookExchange private myOrder; 
    // address public orderBookAddress;
    //IERC721 private myIERC;

    mapping(uint256 => mapping(uint256 => address)) tokenIdtoStaker;
    mapping(address => uint256) public stake;
    mapping(address => bool) exists;
    mapping(address => uint256) stakerTostakeNo;
    mapping(address => uint256)  limitation;

    struct Proposal {
        address proposer;
        uint256 nftTokenId;
        uint256 targetAmount;
        uint256 currentAmount;
        mapping(address => uint256) contributions;
        mapping(address => uint256) shares;
        uint256 deadline;
        bool closed;
        string nftURI;
        address[] contributor;
    }

    mapping(uint => Proposal) public proposals;
    uint public proposalCounter;
    uint public proposalSucceedId;
    uint public contributorAmount;
    address[] private keys;
    mapping(address => uint) cc;
    uint stakerNo;

    event ProposalCreated(uint indexed proposalId, address indexed proposer, string nftURI, uint targetAmount, uint deadline);
    event ContributionAdded(uint indexed proposalId, address indexed contributor, uint amount);
    event ProposalClosed(uint indexed proposalId);

    constructor(address nftExchangeAddress, address myNFTAddress) {
        nftExchange = NFTExchange(nftExchangeAddress);
        myNFT = MyNFT(myNFTAddress);
        // myOrder = OrderBookExchange(myOrderAddress);
        // orderBookAddress = myOrderAddress;
        owner = msg.sender;
        //myIERC = IERC721(myNFTAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }


    function createProposal(uint256 _tokenId, uint256 _targetAmount, uint256 _deadline) external {
        require(_deadline > block.timestamp, "Deadline must be in the future");

        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposer = msg.sender;
        proposal.nftTokenId = _tokenId;
        proposal.targetAmount = _targetAmount;
        proposal.currentAmount = 0;
        proposal.deadline = _deadline;
        proposal.nftURI = myNFT.tokenURI(_tokenId);

        emit ProposalCreated(proposalCounter, msg.sender, proposal.nftURI, _targetAmount, _deadline);
    }


    function contribute(uint _proposalId) external payable {
    Proposal storage proposal = proposals[_proposalId];
    require(!hasExpired(_proposalId), "Proposal has expired");
    require(!proposal.closed, "Proposal is closed");

    uint remainingAmount = proposal.targetAmount - proposal.currentAmount;
    
    proposal.contributor.push(msg.sender);
    contributorAmount++; //贡献权益者数量
    exists[msg.sender] = true;

    if (msg.value >= remainingAmount) {
        proposal.contributions[msg.sender] += remainingAmount;
        proposal.currentAmount += remainingAmount;

        stake[msg.sender]=remainingAmount;
        uint tokenId = proposals[_proposalId].nftTokenId;
        tokenIdtoStaker[tokenId][contributorAmount]=msg.sender;
        stakerTostakeNo[msg.sender] = contributorAmount;
        payable(address(this)).transfer(remainingAmount/20);
        cc[msg.sender] = remainingAmount;
        keys.push(msg.sender);

        emit ContributionAdded(_proposalId, msg.sender, remainingAmount);

        if (proposal.currentAmount >= proposal.targetAmount) {
            closeProposal(_proposalId);
            proposalSucceedId = _proposalId;
        }

        if (msg.value > remainingAmount) {
            uint excessAmount = msg.value - remainingAmount;
            (bool success, ) = payable(msg.sender).call{value: excessAmount}("");
            require(success, "Failed to refund excess payment");
        }
    } else {
        require(msg.value > 0, "Insufficient payment");

        proposal.contributions[msg.sender] += msg.value;
        proposal.currentAmount += msg.value;

        stake[msg.sender]=msg.value;
        uint tokenId = proposals[_proposalId].nftTokenId;
        tokenIdtoStaker[tokenId][contributorAmount]=msg.sender;
        stakerTostakeNo[msg.sender] = contributorAmount;
        payable(address(this)).transfer(msg.value/20);
        cc[msg.sender] = msg.value;
        keys.push(msg.sender);

        emit ContributionAdded(_proposalId, msg.sender, msg.value);
        if (proposal.currentAmount >= proposal.targetAmount) {
            closeProposal(_proposalId);
            proposalSucceedId = _proposalId;
            nftExchange.AfterVotingbuyNFT(proposal.nftTokenId,address(this));
            
        } 
    }
   
    stakerNo = contributorAmount;
}



    function hasExpired(uint _proposalId) public view returns (bool) {
        return block.timestamp >= proposals[_proposalId].deadline || proposals[_proposalId].closed;
    }

    function closeProposal(uint _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.closed, "Proposal is already closed");

        distributeShares(_proposalId);
        proposal.closed = true;

        emit ProposalClosed(_proposalId);

        // if (proposal.currentAmount == proposal.targetAmount) {
        //     // Call the buyNFT function of the NFTExchange contract to purchase the NFT in the user's proposal
        //     nftExchange.buyNFT(proposal.nftTokenId);
        // }
    }

    function distributeShares(uint _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.currentAmount >= proposal.targetAmount, "Target amount not reached");

        uint totalContributions = proposal.currentAmount;
        uint targetAmount = proposal.targetAmount;

        uint _tokenId = proposals[_proposalId].nftTokenId;
        string memory tokenIdStr = tokenIdToString(_tokenId);
        // 创建 ERC20 代币，并指定代币数量
        string memory name = string(abi.encodePacked("Token", tokenIdStr));
        string memory symbol = string(abi.encodePacked("TKN", tokenIdStr));

        uint256 tokenAmount = proposal.targetAmount;
        myToken = new MyToken(name, symbol);
        myToken.createToken(address(this),name,symbol,tokenAmount);

        for (uint i = 1; i <= proposalCounter; i++) {
            Proposal storage p = proposals[i];
            if (i != _proposalId && !hasExpired(i)) {
                uint share = (p.targetAmount * totalContributions) / targetAmount;
                p.shares[msg.sender] = share;
                
            }
        }

        for (uint256 i = 0; i < keys.length; i++) {
            address key = keys[i];
            myToken.approve(address(this), tokenAmount);
            myToken.transferFrom(address(this), key, cc[key]);
        }

    }

    function getContributorShare(uint _proposalId, address _contributor) public view returns (uint) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.closed || hasExpired(_proposalId)) {
            return proposal.contributions[_contributor];
        } else {
            return 0;
        }
    }

    //address[] public IdSucceedContributor = proposals[proposalSucceedId].contributor;

     function getSucceedProposalContributor() public view returns (address[] memory) {
        return proposals[proposalSucceedId].contributor;
    }

    function getSucceedProposalAmount() public view returns (uint) {
    //    IdSucceedContributor = proposals[proposalSucceedId].contributor;
       return proposals[proposalSucceedId].targetAmount;
    }

    function getShare(uint _proposalId, address _contributor) public view returns (uint) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.closed || hasExpired(_proposalId)) {
            return proposal.shares[_contributor];
        } else {
            return 0;
        }
    }

    function transferEther(address payable _recipient, uint256 _transferCount) internal {
        require(_recipient != address(0), "Invalid recipient address");
        require(_transferCount > 0, "Invalid transfer amount");
        address payable sender = payable(msg.sender);
        require(sender.balance >= _transferCount, "Insufficient balance");

        sender.transfer(_transferCount);    
        _recipient.transfer(_transferCount);
    }

    function limitTransfer(uint256 _transferCount) public returns(bool){   //权益拥有方限制转移的数量
        require(_transferCount <= stake[msg.sender],"insufficient fund");
        limitation[msg.sender] = _transferCount;
        return true;
    }

    function transferSlices(address _sender,uint256 _tokenId,uint256 _transferCount) public {    //转移权益，from为_sender地址，to为msg.sender地址，nftID号，转移切片数<=授权数
        //require(msg.sender == admin, "Only admin can transfer slices");
        //require(sliceCount <= 10000, "Maximum slices reached");
        //require(_transferCount <= stake[_sender],"insufficient fund");
        require(_transferCount <= limitation[_sender],"exceeded limitation");
        if (!exists[msg.sender]) {
            stakerNo++;
            tokenIdtoStaker[_tokenId][stakerNo]=msg.sender;
            exists[msg.sender] = true;
            stake[_sender] -=_transferCount;//转移未扣取权益，对于用户号需要改进不？
            stake[msg.sender] +=_transferCount;
            transferEther(payable(_sender),_transferCount);
        }else{
            stake[_sender] -=_transferCount;
            stake[msg.sender]+=_transferCount;
            transferEther(payable(_sender),_transferCount);
        }
    }

    function TokenIdTofindStaker(uint256 _aimTokenId) public view returns (address[] memory){   //根据nftID号找到权益持有者的地址，输入：nftID号，输出：权益拥有者地址数组
        address[] memory staker = new address[](stakerNo); 
        for (uint256 i=1;i<=stakerNo;i++){
             address outcome = tokenIdtoStaker[_aimTokenId][i];
             staker[i-1] = outcome;
             //emit PrintfindStaker(outcome);
        }
        return staker;
    }
    
    //event PrintfindStake(uint256 answerfindStake);
    function TokenIdToStake(uint256 _aimTokenId) public view returns (uint256[] memory){    //根据nftID号，找到该nft的权益分割情况，输入：nftID号，输出：权益分割情况的数组
        uint256[] memory st = new uint256[](stakerNo);
        for (uint256 i=1;i<=stakerNo;i++){
            uint256 outcome = stake[tokenIdtoStaker[_aimTokenId][i]];
            st[i-1] = outcome;
            //emit PrintfindStake(outcome);
        }  
        return st;
    }
    
    function findstakeNo (address _aimStaker) public view returns (uint256){    //输入地址，找到对应的权益持有者ID号，输入：地址，返回：权益持有者ID号
        return stakerTostakeNo[_aimStaker];
    }

    function findStake (address _aimStaker) public view returns (uint256){  //输入地址，找到对应拥有的权益，输入：地址，输出：对应权益
        return stake[_aimStaker];
    }
    function tokenIdToString(uint256 _tokenId) internal pure returns (string memory) {
        return Strings.toString(_tokenId);
    }
    function getMyTokenAddress() public view returns (address) {
        return address(myToken);
    }

    // 暴露一个函数来访问 MyToken 合约
    function getMyTokenApprove(address spender, uint256 amount) external{
        myToken.approve(spender, amount);
    }

    struct Order {
        address payable trader; // 将 trader 的类型改为 address
        uint256 amount;
        uint256 price;
        bool isBuy;
    }

    mapping(address => mapping(address => uint256)) public tokenBalances;
    mapping(address => Order[]) public buyOrders;
    mapping(address => Order[]) public sellOrders;

    event OrderCreated(address indexed trader, address indexed token, uint256 amount, uint256 price, bool isBuyOrder);
    event TradeExecuted(address indexed token, uint256 amount, uint256 price);

   function createBuyOrder(address token, uint256 amount, uint256 price) external {
    require(amount > 0, "Amount must be greater than zero");
    IERC20(token).approve(address(this), amount);
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    buyOrders[token].push(Order(payable(msg.sender), amount, price, true)); // 将 trader 转换为 payable(address)

    emit OrderCreated(msg.sender, token, amount, price, true);
}

function createSellOrder(address token, uint256 amount, uint256 price) external {
    require(amount > 0, "Amount must be greater than zero");
    IERC20(token).approve(address(this), amount);
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    sellOrders[token].push(Order(payable(msg.sender), amount, price, false)); // 将 trader 转换为 payable(address)

    emit OrderCreated(msg.sender, token, amount, price, false);
}

function executeTrades(address token) external {
    Order[] storage buys = buyOrders[token];
    Order[] storage sells = sellOrders[token];

    for (uint256 i = 0; i < buys.length; i++) {
        for (uint256 j = 0; j < sells.length; j++) {
            if (buys[i].price >= sells[j].price && buys[i].amount > 0 && sells[j].amount > 0) {
                uint256 tradeAmount = (buys[i].amount < sells[j].amount) ? buys[i].amount : sells[j].amount;
                uint256 tradeValue = tradeAmount * buys[i].price;

                IERC20(token).transferFrom(address(this), buys[i].trader, tradeAmount);
                IERC20(token).transfer(buys[i].trader, tradeAmount);

                buys[i].amount -= tradeAmount;
                sells[j].amount -= tradeAmount;

                buys[i].trader.transfer(tradeValue);
                sells[j].trader.transfer(tradeAmount);

                emit TradeExecuted(token, tradeAmount, tradeValue);
            }
        }
    }
}

    function getBuyOrders(address token) external view returns (Order[] memory) {
        return buyOrders[token];
    }

    function getSellOrders(address token) external view returns (Order[] memory) {
        return sellOrders[token];
    }

    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    // Implement a receive function to receive ether
    receive() external payable {}

    
}
