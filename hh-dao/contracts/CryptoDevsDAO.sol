// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";


// Fake NFT marketplace Interface
interface IFakeNFTMarketplace {
    // get price from of NFT from fake marketplace
    function getPrice() external view returns (uint256);
    
    // returns if a _tokenId has been sold or not
    function available(uint256 _tokenId) external view returns (bool);

    // purchases an NFT from the fake market place
    function purchase(uint256 _tokenId) external payable;
}

// Crypto Dev NFT interface
interface ICryptoDevsNFT {
    // returns the number of NFTs owned by an address
    function balanceOf(address owner) external view returns (uint256);

    // returns the TokenId of an NFT at given index for owner
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}



contract CryptoDevsDAO is Ownable {

    // Variables for marketplace and cryptodevs
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    // Create a struct containing all relevant information for a proposal
    // Proposal is misspelled in the walk through and might cause an issue when turing in! 
    struct Proposal {
        // tokenId of the NFT to purchase
        uint256 nftTokenId;
        // UNIX timestamp for how long the proposal will be activate owner
        uint256 deadline;
        // number of yes votes
        uint256 yayVotes;
        // number of no votes
        uint256 nayVotes;
        // whether or not the proposal has been executed, cannot be executed before deadline has passed
        bool executed;
        // mapping nfts tokenIds to bool to indicate if that NFT has voted or not
        mapping(uint256 => bool) voters;
    }
    // Create a mapping ID of the Proposal
    mapping(uint256 => Proposal) public proposals;

    // number of proposals that have been created
    uint256 public numProposals;



    // create a modifier which only allows fucntions to be called
    // by someone who owns at least one NFT
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "Not a DAO member");
        _;
    }

    // modifier to only allow voting before the deadline is exceeded
    modifier activateProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline > block.timestamp, "Dead line exceeded");
        _;
    }

    // Modifire that allows the function to be called if deadline has been exceeded and proposal has not been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline <= block.timestamp, "Deadline not exceeded");
        require(proposals[proposalIndex].executed == false, "Proposal already executed");
        _;
    }

    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 0
    }

    // Create a payable constructor which initializes the contracts
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }



    // Allows for CryptoDevNFT holders to create a new proposal in the DAO
    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT Not for sale!");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        // set the proposal voting deadline for 5 minutes
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activateProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint numVotes = 0;

        // Calculate how many NFTs are owned by voters
        // that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "Already Voted");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // execute proposal allows cryptoDevNFT holders to execute a proposal after its deadline
    function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        // if proposal has more yay votes than nay
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "Not enough funds");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);

        }
        proposal.executed = true;
    }

    // allows contract owner to withdraw ETH from contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Allow for depositin of ETH
    receive() external payable {}

    fallback() external payable {}

}