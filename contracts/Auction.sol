// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Auction is ERC721URIStorage {
    using Counters for Counters.Counter;
    // uint public Time = block.timestamp;
    event alaki(uint256 _alaki);

    IERC721 public nft;
    address nftAddress;
    mapping(address => mapping(uint256 => uint256)) public Bids;
    mapping(uint256 => auction) public AuctionComponents;
    mapping(uint256 => address[]) AllBidders;

    Counters.Counter public _tokenIds;

    struct auction {
        address owner;
        address seller;
        address nftAddress;
        uint256 HighestBid;
        address HighestBidder;
        uint256 EndTime;
        bool Canceled;
    }

    constructor() ERC721("KNG", "Kourosh") {
        nft = ERC721(nftAddress);
    }

    modifier Ended(uint256 _NewTokenId) {
        require(
            block.timestamp < AuctionComponents[_NewTokenId].EndTime,
            "This auction has Ended."
        );
        _;
    }

    modifier OnlyOwner(uint256 _tokenId) {
        require(msg.sender == AuctionComponents[_tokenId].seller, "Not Owner");
        _;
    }

    modifier NotEndedYet(uint256 _tokenId) {
        require(
            block.timestamp > AuctionComponents[_tokenId].EndTime,
            "this auction has not ended yet!!!"
        );
        _;
    }

    function CancelAuction(uint256 _tokenId) external OnlyOwner(_tokenId) {
        require(
            block.timestamp < AuctionComponents[_tokenId].EndTime,
            "Not able to cancel right now"
        );
        require(
            AuctionComponents[_tokenId].Canceled == false,
            "Already cancele"
        );

        AuctionComponents[_tokenId].Canceled = true;
    }

    function CreateAuctionComponents(
        uint256 _tokenId,
        uint256 _price,
        address _nftAddress
    ) private {
        require(_price > 0, "Set amount of money for your token");
        AuctionComponents[_tokenId] = auction(
            address(this),
            msg.sender,
            _nftAddress,
            _price,
            address(0),
            block.timestamp + 1 minutes,
            false
        );
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
    }

    function CreateAuctionToken(
        string memory _tokenURI,
        uint256 _price,
        address _nftAddress
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 NewTokenId = _tokenIds.current();
        _mint(msg.sender, NewTokenId);
        _setTokenURI(NewTokenId, _tokenURI);
        CreateAuctionComponents(NewTokenId, _price, _nftAddress);
        emit alaki(NewTokenId);
        return NewTokenId;
    }

    function Bid(uint256 _tokenId) external payable Ended(_tokenId) {
        require(
            msg.value + Bids[msg.sender][_tokenId] >
                AuctionComponents[_tokenId].HighestBid,
            "It is less than highest Bid"
        );
        require(
            !AuctionComponents[_tokenId].Canceled,
            "This auction has canceled"
        );

        if (msg.sender != address(0)) {
            Bids[msg.sender][_tokenId] += msg.value;
        }

        AllBidders[_tokenId].push(msg.sender);
        AuctionComponents[_tokenId].HighestBid = msg.value;
        AuctionComponents[_tokenId].HighestBidder = msg.sender;
    }

    function WinnerPrize(uint256 _tokenId, address _nftAddress)
        external
        payable
        NotEndedYet(_tokenId)
        OnlyOwner(_tokenId)
    {
        uint256 highestBid = AuctionComponents[_tokenId].HighestBid;
        if (AuctionComponents[_tokenId].HighestBidder != address(0)) {
            IERC721(_nftAddress).transferFrom(
                address(this),
                AuctionComponents[_tokenId].HighestBidder,
                _tokenId
            );
            payable(AuctionComponents[_tokenId].seller).transfer(highestBid);
            AuctionComponents[_tokenId] = auction(
                msg.sender,
                address(0),
                _nftAddress,
                0,
                msg.sender,
                0,
                true
            );
        } else {
            IERC721(_nftAddress).transferFrom(
                address(this),
                AuctionComponents[_tokenId].seller,
                _tokenId
            );
            AuctionComponents[_tokenId].owner = msg.sender;
            AuctionComponents[_tokenId].seller = address(0);
        }
    }

    function AllBiddersToTokenID(uint256 _tokenId)
        public
        view
        returns (address[] memory)
    {
        return AllBidders[_tokenId];
    }

    function AllBidsToTokend(uint256 _tokenId) public view returns (uint256) {
        return Bids[msg.sender][_tokenId];
    }

    function Retake(uint256 _tokenId) external payable NotEndedYet(_tokenId) {
        require(Bids[msg.sender][_tokenId] != 0, "Balance Already Zero!!!");
        uint256 bal = Bids[msg.sender][_tokenId];
        Bids[msg.sender][_tokenId] = 0;
        payable(msg.sender).transfer(bal);
    }

    function RetakeWhenCanceled(uint256 _tokenId) external payable {
        require(
            AuctionComponents[_tokenId].Canceled,
            "This auction is Ungoing"
        );
        require(Bids[msg.sender][_tokenId] != 0, "Balance Already Zero!!!");
        uint256 bal = Bids[msg.sender][_tokenId];
        Bids[msg.sender][_tokenId] = 0;
        payable(msg.sender).transfer(bal);
    }
}
