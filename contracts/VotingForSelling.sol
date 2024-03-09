// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./NewParams.sol";
import "./NFTVote.sol";

contract VotingForSelling{

    struct Proposal {//定义一个提案结构体，包括提案id，描述，投入价格和是否存在
        uint256 id;
        string description ;
        uint256 voteCount;
        bool exists;
        uint nftTokenId;
    }

    address public owner;  //合约拥有者的地址
    mapping(uint256 => Proposal) public proposals;// 存储所有提案的映射表，其中键为提案 ID，值为 Proposal 结构体。
    uint256 public proposalCount; //提案计数器，用于给新提案分配唯一的 ID。
    mapping(address => bool) public voters; //存储已投票的地址列表，用于确保一个账户只能投一次票    
    address public targetAddress;
    //NewParams public newparams;
    NFTVote public nftVote;
    //uint256 aimStake;
    uint256 winningIndex;

    event ProposalCreated(uint256 proposalId, string description); //定义了一个事件，用于在新提案创建时通知客户端。

    event Voted(uint256 proposalId, address msgSender,uint256 votePrice); //定义了一个事件，用于在成功投票时通知客户端

    constructor(address payable _targetAddress) {
        owner = msg.sender;
        proposalCount = 0;
        //newparams = NewParams(_targetAddress); 
        nftVote = NFTVote(_targetAddress);
    }

    modifier onlyOwner() { //限制只有合约拥有者能够调用的函数修饰符。
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyOnce() { //限制一个账户只能投一次票的函数修饰符。

        require(!voters[msg.sender], "You can only vote once.");
        _;
    }

    function createProposal(string memory description, uint _nftTokenId) public onlyOwner { //创建新提案的函数，只能由合约拥有者调用。它会增加提案计数器 `proposalCount`，然后将新提案存入 `proposals` 映射表中，包括提案 ID、描述、投票数和是否存在。最后会触发 `ProposalCreated` 事件。
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, description, 0, true,_nftTokenId);
        emit ProposalCreated(proposalCount, description);

    }

    /*function findStake (address _aimStaker) public view returns (uint256){
        return stake[_aimStaker];
    }*/
   
    function vote(uint256 _proposalId) public onlyOnce {  //投票函数，确保调用者没有投过票，并将投票数增加 1。最后会将调用者的地址添加到 `voters` 列表中，防止重复投票。如果提案不存在，则会抛出异常。最后会触发 `Voted` 事件
        require(proposals[_proposalId].exists, "Proposal does not exist.");
        proposals[_proposalId].voteCount+= /*newparams*/nftVote.findStake(msg.sender);
        voters[msg.sender] = true; 
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].voteCount > /*newparams*/nftVote.getSucceedProposalAmount()/2) {
                winningIndex = i;
            }
        }
        emit Voted(_proposalId, msg.sender, /*newparams*/nftVote.findStake(msg.sender));
    }

    function getWinningProposal() public view returns (uint256 winningProposalId, string memory description) { //获取获胜提案的函数，它会迭代所有提案并找到当所提供权益超过总价的一半时获胜的那一个提案。然后返回获胜提案的 ID、描述和投票数。
        winningProposalId = proposals[winningIndex].id;
        description = proposals[winningIndex].description;
    }
}