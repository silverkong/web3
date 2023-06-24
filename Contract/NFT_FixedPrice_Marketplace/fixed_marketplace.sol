// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../NFT_Staking/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FixedPriceMarketPlace is IERC721Receiver, ReentrancyGuard {
  // Can payable thisAddress
  address payable thisAddress;
  // listingFee is 1 ether
  uint256 listingFee = 1 ether;
  // mapping ActiveList using number
  mapping(uint256 => ActiveList) public checkUploadItems;

  /////////////////////////
  //  ActiveList struct  //
  /////////////////////////
  struct ActiveList {
    uint256 NFTId;
    address payable NFTSeller;
    address payable thisAddress;
    uint256 NFTPrice;
    bool isSold;
  }

  ////////////////////////////////////////
  //  EVENT (with emit) NFTListCreated  //
  ////////////////////////////////////////
  event NFTListCreated (
    uint256 indexed NFTId,
    address NFTSeller,
    address thisAddress,
    uint256 NFTPrice,
    bool isSold
  );

  // Listed NFT Price
  function FixedNFTPrice() public view returns (uint256) {
    return listingFee;
  }

  ERC721A nft;

   constructor(ERC721A _nft) {
    thisAddress = payable(msg.sender);
    nft = _nft;
  }

  function buyListedNft(uint256 NFTId) public payable nonReentrant {
      uint256 NFTPrice = checkUploadItems[NFTId].NFTPrice;
      require(msg.value == NFTPrice, "!!msg.value is not same with NFTPrice!!");
      checkUploadItems[NFTId].NFTSeller.transfer(msg.value);
      // Add your owner address, get comission
      payable({change this line}).transfer(listingFee);
      nft.transferFrom(address(this), msg.sender, NFTId);
      checkUploadItems[NFTId].isSold = true;
      delete checkUploadItems[NFTId];
  }

  function canceledNFTSale(uint256 NFTId) public nonReentrant {
      require(checkUploadItems[NFTId].NFTSeller == msg.sender, "!NFT is not yours!");
      // Add your owner address, get comission
      payable({change this line}).transfer(listingFee);
      nft.transferFrom(address(this), msg.sender, NFTId);
      delete checkUploadItems[NFTId];
  }

  /////////////////////
  // Upload NFT list //
  /////////////////////

  function NFTlistSale(uint256 NFTId, uint256 NFTPrice) public payable nonReentrant {
      require(nft.ownerOf(NFTId) == msg.sender, "!NFT is not Yours!");
      require(checkUploadItems[NFTId].NFTId == 0, "!NFT already listed!");
      require(NFTPrice > 0, "!Amount over than 0!");
      require(msg.value == listingFee, "!transfer 1 eth!");
      
      checkUploadItems[NFTId] =  ActiveList(NFTId, payable(msg.sender), payable(address(this)), NFTPrice, false);
      nft.transferFrom(msg.sender, address(this), NFTId);
      emit NFTListCreated(NFTId, msg.sender, address(this), NFTPrice, false);
  }

  ////////////////////////
  //  Check Listed NFT  //
  ////////////////////////

 function showNFTListings() public view returns (ActiveList[] memory) {
    uint256 nftCount = nft.totalSupply();
    uint currentIndex = 0;
    ActiveList[] memory listItems = new ActiveList[](nftCount);
    for (uint i = 0; i < nftCount;) {
      // (checkUploadItems[i + 1]) 1번부터 먹게되어있어서 tokenid가 0부터 시작하면 checkUploadItems[i]로 만들어야 함!
        if (checkUploadItems[i].thisAddress == address(this)) {
        uint currentId = i;
        ActiveList storage currentItem = checkUploadItems[currentId];
        listItems[currentIndex] = currentItem;
        currentIndex += 1;
      }
      i++;
    }
    return listItems;
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