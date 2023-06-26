// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// co-op contract
import "./ERC721A.sol";

contract Hacker_Haus is ERC721A, Ownable {
    //MAX_MINTS = 한 지갑당 가질수 있는 최대 개수
    uint256 MAX_MINTS = 5;

    //maxPurchase = 한번 민팅에 최대 민팅 개수
    uint256 public constant maxPurchase = 3;

    //총 NFT 개수, 화리 NFT 개수, 팀물량
    uint256 public MAX_SUPPLY = 50;
    uint256 public WL_MAX_SUPPLY = 25;
    uint256 public TEAM_SUPPLY = 12;

    //퍼블릭민팅 가격, 화이트 리스트 민팅 가격
    uint256 public PRICE_PER_ETH = 0.000 ether;
    uint256 public WL_PRICE_PER_ETH = 0.000 ether;

    mapping(address => bool) public whitelisted;
    uint256 public numWhitelisted;

    //_baseTokenURI = 껍데기, notRevealedUri = 리빌 버튼을 눌렀을때 나오는 원본
    string private _baseTokenURI;
    string public notRevealedUri;

    //sale start false or true
    bool public isSale = false;
    bool public WLisSale = false;

    //reveal은 처음에 false
    bool public revealed = false;


    //이걸로 주면 30번째줄이 허용됨 이유는 TEST_ERC721A_V2는 TEST1을 가지고 있기 때문에
    TEST_ERC721A_V2 nft1;

    constructor(string memory baseTokenURI, string memory _initNotRevealedUri, TEST_ERC721A_V2 _nft1) ERC721A("Hacker_Haus", "Hacker_Haus_NFT") {
        _baseTokenURI = baseTokenURI;
        setNotRevealedURI(_initNotRevealedUri);
        nft1 = TEST_ERC721A_V2(_nft1);
    }

    function mintByETH(uint256 quantity, uint256 tokenId) external payable {
        require(isSale, "Not Start");
        //require(nft1.balanceOf(msg.sender) > 3, "you have more 3 nft");
        //_numberMinted(msg.sender)
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit per wallet");

        require(quantity <= maxPurchase, "Can only mint N amount NFT at a time");

        require(nft1.TEST1(msg.sender) >= 5, "you have more 5 nft");
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        
        require(msg.value >= (PRICE_PER_ETH * quantity), "Not enough ether sent");

        if(nft1.random4() == true) {
        _safeMint(msg.sender, quantity); }
        else {
            //_safeMint(msg.sender, quantity);
            nft1.burn(tokenId);
        }
    }

    

    function WLmintByETH(uint256 quantity) external payable {
        require(WLisSale, "Not Start");
        require(whitelisted[msg.sender] == true, "You are not white list");
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit per wallet");
        require(quantity <= maxPurchase, "Can only mint N amount NFT at a time");
        require(nft1.TEST1(msg.sender) >= 5, "you have more 5 nft");
        require(totalSupply() + quantity <= WL_MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (WL_PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function developerPreMint(uint256 quantity) external payable {
        //isSale False
        require(!isSale, "Not Start");
        //지갑당 N개만 가지고 있을 수 있음
        require(quantity + _numberMinted(msg.sender) <= TEAM_SUPPLY, "Exceeded the limit per wallet");
        //총 개수 제한, NFT N개 제한
        require(totalSupply() + quantity <= TEAM_SUPPLY, "Not enough tokens(NFT) left");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //BBGTContract nft1
    /*function burn123(uint256 tokenId) public payable{
        nft1.burn{value:msg.value}(tokenId);
    }*/

    function burn123(uint256 tokenId) public payable{
        require(nft1.ownerOf(tokenId) == msg.sender, "Not your nft1's nft");
        nft1.burn(tokenId);
    } 

    function withdraw123567(address metamask) public view returns (uint256) {
        return nft1.TEST1(metamask);
    }

    function turefalseget() public view returns (bool) {
        return nft1.random4();
    }

    /* function TEST0() public view returns (uint256) {
        //ERC721A contract가 사람들이 민팅을 했을때 가지는 이더 량
        return address(this).balance;
    } */

    function TEST1(address metamask) public view returns (uint256) {
        //이 주소가 NFT를 몇개나 민팅했는지 이건 트렌스퍼 해도 안바뀜
        //Ex) 3개 민팅해서 1개를 다른사람한테 보낸다고 해도 numberMinted는 여전히 3개 고정
        return _numberMinted(metamask);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {

        if(revealed) { 
            return notRevealedUri; 
        }

        return _baseTokenURI;
    }

    function setSale() public onlyOwner {
        isSale = !isSale;
    }

    function WLsetSale() public onlyOwner {
        WLisSale = !WLisSale;
    }

    /* function getWLpublicSale() public view returns (uint256) {
        return WL_PRICE_PER_ETH;
    }

    function getpublicSale() public view returns (uint256) {
        return PRICE_PER_ETH;
    }

    function increasePrice() public onlyOwner {
        PRICE_PER_ETH += 0.2 ether;
    } */

    function addWhitelist(address[] memory _users) public onlyOwner {
        uint256 size = _users.length;
       
        for (uint256 i=0; i< size; i++){
            address user = _users[i];
            whitelisted[user] = true;
        }
        numWhitelisted += _users.length;
    }

    function removeWhitelist(address[] memory _users) public onlyOwner {
        uint256 size = _users.length;
        
        for (uint256 i=0; i< size; i++){
            address user = _users[i];
            whitelisted[user] = false;
        }
        numWhitelisted -= _users.length;
    }
}