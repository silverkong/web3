// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract MarketPlace is IERC721Receiver, Ownable, ReentrancyGuard {
    // Can payable thisAddress
    address payable thisAddress;
    // listingFee is 1 ether : listing 수수료
    uint256 listingFee = 1 ether;
    // mapping ActiveList using number
    mapping(uint256 => ActiveList) public checkUploadItems;

    uint256 public nftListedCount = 0;

    /////////////////////////
    //  ActiveList struct  //
    /////////////////////////
    struct ActiveList {
        uint256 NFTId;
        address payable NFTSeller;
        address payable thisAddress; // Contract Address
        uint256 NFTPrice;
        bool isSold;
    }

    ////////////////////////////////////////
    //  EVENT (with emit) NFTListCreated  //
    ////////////////////////////////////////
    event NFTListCreated (
        uint256 indexed NFTId,
        address NFTSeller, // msg.sender
        address thisAddress,
        uint256 NFTPrice,
        bool isSold
    );

    // NFT FixedPrice listingFee
    function FixedNFTPrice() public view returns (uint256) {
        return listingFee;
    }

    ERC721 nft;

    constructor(ERC721 _nft) Ownable(msg.sender) {
        thisAddress = payable(msg.sender); // Contract Address
        nft = _nft;
    }

    // 어떤 NFT를 살건지 = NFTId
    function buyListedNft(uint256 NFTId) public payable nonReentrant {
        uint256 NFTPrice = checkUploadItems[NFTId].NFTPrice;
        // NFT 판매가 = msg.value
        require(msg.value == NFTPrice, "msg.value and NFTPrice are not same");
        checkUploadItems[NFTId].NFTSeller.transfer(msg.value); // [NFTId]의 아이템에서 NFTSeller의 주소에 msg.value 값을 보냄
        nft.transferFrom(address(this), msg.sender, NFTId); // Contract의 주소에서 msg.sender로 NFT 전송
        checkUploadItems[NFTId].isSold = true;
        delete checkUploadItems[NFTId];
    }

    // 어떤 NFT를 취소할 건지 = NFTId
    function canceledNFTSale(uint256 NFTId) public nonReentrant {
        // NFT 주인인지 확인
        require(checkUploadItems[NFTId].NFTSeller == msg.sender, "NFT is not yours");
        // Add your owner address, get comission, Only 50% of the listingfee is refunded
        payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4).transfer(listingFee / 2);
        nft.transferFrom(address(this), msg.sender, NFTId);
        nftListedCount--;
        delete checkUploadItems[NFTId];
    }

    ///////////////////////
    //  Upload NFT list  //
    ///////////////////////
    function NFTlistSale(uint256 NFTId, uint256 NFTPrice) public payable nonReentrant {
        require(nft.ownerOf(NFTId) == msg.sender, "NFT is not yours"); // 내 NFT인지 확인
        require(checkUploadItems[NFTId].NFTId == 0, "NFT already listed"); // NFT가 list에 올라가있는지 확인
        require(NFTPrice > 0, "NFT Price over than 0!"); // NFT Price가 0 이상인지 확인
        require(msg.value == listingFee, "Listing Fee required"); // listingFee 값이 있는지 확인
        // struct 안에 있는 주소에 쏴야하기 때문에 payable이 필요
        checkUploadItems[NFTId] =  ActiveList(NFTId, payable(msg.sender), payable(address(this)), NFTPrice, false);
        nft.transferFrom(msg.sender, address(this), NFTId);
        nftListedCount++;
        emit NFTListCreated(NFTId, msg.sender, address(this), NFTPrice, false);
    }

    /////////////////////////
    //   Check Listed NFT  //
    /////////////////////////
    function showNFTListings() public view returns (ActiveList[] memory) {
        // 동적 배열 : 이유 ) 100개를 잡으면 손해고, 10개로 잡았을 땐 너무 적어서 안 올라갈 수 있음
        ActiveList[] memory listItems = new ActiveList[](nftListedCount);
        uint256 counter = 0;
        // Loop through all NFTIds in checkUploadItems
        for (uint256 i = 1; i <= nftListedCount; i++) {
            if (checkUploadItems[i].thisAddress == address(this)) {
                listItems[counter] = checkUploadItems[i];
                counter++;
            }
        }
        return listItems;
    }

    /////////////////////
    // England Auction //
    /////////////////////

    struct EnglandAuction {
        uint256 NFTId;
        address payable seller;
        uint256 startingPrice;
        uint256 endTime;
        address payable highestBidder;
        uint256 highestBid;
        bool ended;
        bool cancelled;
        uint256 dueDate;
    }

    mapping(uint256 => EnglandAuction) public englandAuctions;
    uint256 public auctionFee = 1 ether; // 경매 등록 비용

    event AuctionCreated(uint256 indexed NFTId, uint256 startingPrice, uint256 endTime);
    event NewBid(uint256 indexed NFTId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed NFTId, address winner, uint256 amount);

    function createAuction(uint256 NFTId, uint256 startingPrice, uint256 duration) public payable nonReentrant {
        require(nft.ownerOf(NFTId) == msg.sender, "NFT is not yours");
        require(msg.value == auctionFee, "Auction Fee required");

        /////////////////////////////////////////////////
        // NFTId : NFT id                              //
        // seller : 본인 (돈 받아야해서 payable)           //
        // startingPrice : 초기 가격                     //
        // endTime : 현재 블럭 + 내가 설정한 duration       //
        // highestBidder : 높은 가격 제시한 주소            //
        // highestBid : 높은 가격                        //
        // ended : Auction이 종료되었는지 (true/false)     //
        // cancelled : Auction이 취소되었는지 (true/false) //
        // duration : 초                                //
        /////////////////////////////////////////////////
        englandAuctions[NFTId] = EnglandAuction({
            NFTId: NFTId,
            seller: payable(msg.sender),
            startingPrice: startingPrice,
            endTime: block.timestamp + duration,
            highestBidder: payable(address(0)),
            highestBid: 0,
            ended: false,
            cancelled: false,
            dueDate : duration
        });

        // Contract Address로 NFT 이동. 본인(msg.sender)이 이 주소로 N번째 nft 이동
        nft.transferFrom(msg.sender, address(this), NFTId);

        // Event log
        emit AuctionCreated(NFTId, startingPrice, block.timestamp + duration);
    }

    function bid(uint256 NFTId) public payable nonReentrant {
        EnglandAuction storage auction = englandAuctions[NFTId];
        require(block.timestamp < auction.endTime, "England auction already done");
        require(msg.value > auction.highestBid, "There is a higher bid");

        if (auction.highestBid != 0) { // auction.highestBid != 0 : 경매가 시작 됨
            auction.highestBidder.transfer(auction.highestBid);
        }

        // payable로 인하여 이렇게 msg.sender가 받을 수 있음
        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;
        
        emit NewBid(NFTId, msg.sender, msg.value);
    }

    function endAuction(uint256 NFTId) public nonReentrant {
        EnglandAuction storage auction = englandAuctions[NFTId];
        require(block.timestamp > auction.endTime, "England auction not over yet");
        require(!auction.ended, "England auction has already been done");

        auction.ended = true;

        if (auction.highestBidder != address(0)) { // 주소가 있다면,
            // If there was at least one bid, transfer funds to the seller
            // auction seller가 높은 금액 전송
            auction.seller.transfer(auction.highestBid);
            // Contract에서 highestBidder에게 NFT 전송
            nft.transferFrom(address(this), auction.highestBidder, NFTId);
            emit AuctionEnded(NFTId, auction.highestBidder, auction.highestBid);
        } else {
            // If there were no bids, return NFT to the seller
            nft.transferFrom(address(this), auction.seller, NFTId);
            emit AuctionEnded(NFTId, auction.seller, 0);
        }
    }

    ///////////////////
    // Dutch Acution //
    ///////////////////
    struct DutchAuction {
        uint256 NFTId;
        address payable seller;
        uint256 startingPrice;
        uint256 finalLowPrice;
        uint256 declineRate; // price will be reduced by this rate per second
        uint256 startTime;
        bool ended;
    }

    mapping(uint256 => DutchAuction) public dutchAuctions;

    function createDutchAuction(uint256 NFTId, uint256 startingPrice, uint256 finalLowPrice, uint256 declineRate) public payable nonReentrant {
        require(nft.ownerOf(NFTId) == msg.sender, "NFT is not yours!");
        require(msg.value == auctionFee, "Transfer auction fee!");

        ///////////////////////////////////////////
        // NFTId : NFT id                        //
        // seller : 본인 (돈 받아야해서 payable)      //
        // startingPrice : 초기 가격(가장 높은 가격)   //
        // finalLowPrice : 마지막 경매 가격          //
        // declineRate : Price가 떨어지는 비율       //
        // startTime : 시작 시간                   //
        // ended : 끝남?                          //
        ///////////////////////////////////////////
        dutchAuctions[NFTId] = DutchAuction({
            NFTId: NFTId,
            seller: payable(msg.sender),
            startingPrice: startingPrice,
            finalLowPrice: finalLowPrice,
            declineRate: declineRate,
            startTime: block.timestamp,
            ended: false
        });

        nft.transferFrom(msg.sender, address(this), NFTId);
    }

    function getCurrentPrice(uint256 NFTId) public view returns (uint256) {
        DutchAuction storage auction = dutchAuctions[NFTId];
        uint256 elapsedTime = block.timestamp - auction.startTime;
        uint256 priceDecline = elapsedTime * auction.declineRate;
        uint256 currentPrice = auction.startingPrice - priceDecline;

        return currentPrice > auction.finalLowPrice ? currentPrice : auction.finalLowPrice;
    }

    function buyDutchAuction(uint256 NFTId) public payable nonReentrant {
        DutchAuction storage auction = dutchAuctions[NFTId];
        uint256 currentPrice = getCurrentPrice(NFTId);
        require(msg.value >= currentPrice, "The value is below the current price");
        require(!auction.ended, "Dutch Auction already done");

        auction.ended = true;

        auction.seller.transfer(currentPrice);

        nft.transferFrom(address(this), msg.sender, NFTId);
    }

    function cancelDutchAuction(uint256 NFTId) public nonReentrant {
        DutchAuction storage auction = dutchAuctions[NFTId];
        require(msg.sender == auction.seller, "You are not the seller!");
        require(!auction.ended, "Dutch Auction already done");
        
        uint256 currentPrice = getCurrentPrice(NFTId);
        require(currentPrice <= auction.finalLowPrice, "The auction cannot be cancelled above reserve price!");
    
        auction.ended = true;
        
        nft.transferFrom(address(this), msg.sender, NFTId);
    }

    function checkTime() public view returns(uint256){
        uint256 myTime = block.timestamp;
        return myTime;
    }

    ////////////////////////
    //  onERC721Received  //
    ////////////////////////
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}