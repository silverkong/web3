// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// co-op contract
import "https://github.com/sueun-dev/ERC721A_GOMZ/blob/main/contracts/ERC721A.sol";
import "https://github.com/sueun-dev/ERC721_GOMZ/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract TEST_ERC721A_V2 is ERC721A, Ownable {
    //MAX_MINTS = 한 지갑당 가질수 있는 최대 개수
    uint256 MAX_MINTS = 10;

    //maxPurchase = 한번 민팅에 최대 민팅 개수
    uint256 public constant maxPurchase = 3;

    //총 NFT 개수, 화리 NFT 개수, 팀물량
    uint256 public MAX_SUPPLY = 50;
    uint256 public WL_MAX_SUPPLY = 25;
    uint256 public TEAM_SUPPLY = 12;

    //퍼블릭민팅 가격, 화이트 리스트 민팅 가격
    uint256 public PRICE_PER_ETH = 0.0002 ether;
    uint256 public WL_PRICE_PER_ETH = 0.0001 ether;

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


    constructor(string memory baseTokenURI, string memory _initNotRevealedUri) ERC721A("NFT_NAME", "NFT_SYMBOL") {
        //baseTokenURI = 겁데기
        //setNotRevealedURI = 리빌 버튼을 눌렀을때 나오는 원본
        _baseTokenURI = baseTokenURI;
        setNotRevealedURI(_initNotRevealedUri);
    }

    

    function mintByETH(uint256 quantity) external payable {
        require(isSale, "Not Start");
        //지갑당 N개만 가지고 있을 수 있음
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit per wallet");
        //총 개수 제한
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens(NFT) left");
        //한번 민팅당 개수
        require(quantity <= maxPurchase, "Can only mint N amount  NFT at a time");
        //가격 * 물량 < msg.value
        require(msg.value >= (PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }


    function WLmintByETH(uint256 quantity) external payable {
        require(WLisSale, "Not Start");
        //화이트 리스트 확인, 화리라면 true, 화리가 아니라면 false
        require(whitelisted[msg.sender] == true, "You are not white list");
        //지갑당 N개만 가지고 있을 수 있음
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit per wallet");
        //총 개수 제한
        require(totalSupply() + quantity <= WL_MAX_SUPPLY, "Not enough tokens(NFT) left");
        //한번 민팅당 개수
        require(quantity <= maxPurchase, "Can only mint N amount NFT at a time");
        //가격 * 물량 < msg.value
        require(msg.value >= (WL_PRICE_PER_ETH * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    //burn 사용할 경우 매개변수에 burn 넣기 ->  uint256 tokenId
    function developerPreMint(uint256 quantity) external payable {
        //isSale False
        //아래는 내가 가진 토큰만 번 할수있게
        //require(ownerOf(tokenId) == msg.sender, "Not your NFT");
        require(!isSale, "Not Start");
        //지갑당 N개만 가지고 있을 수 있음
        require(quantity + _numberMinted(msg.sender) <= TEAM_SUPPLY, "Exceeded the limit per wallet");
        //총 개수 제한, NFT N개 제한
        require(totalSupply() + quantity <= TEAM_SUPPLY, "Not enough tokens(NFT) left");
        _safeMint(msg.sender, quantity);
        //_burn(tokenId);
    }

    function testPreMint(uint256 quantity, uint256 tokenId) external payable {
        //isSale False
        //아래는 내가 가진 토큰만 번 할수있게
        require(ownerOf(tokenId) == msg.sender, "Not your NFT");
        require(!isSale, "Not Start");
        //지갑당 N개만 가지고 있을 수 있음
        require(quantity + _numberMinted(msg.sender) <= TEAM_SUPPLY, "Exceeded the limit per wallet");
        //총 개수 제한, NFT N개 제한
        require(totalSupply() + quantity <= TEAM_SUPPLY, "Not enough tokens(NFT) left");

        if(random1() == true) {
        _burn(tokenId);}

        _safeMint(msg.sender, quantity);

    }


    //random1 true or false random
    function random1() private view returns(bool){
        uint256 getRandom = uint(keccak256(abi.encodePacked(block.timestamp,block.prevrandao,  
        msg.sender)));
        if(getRandom % 2 == 1) {
            return true;
        }
        else {
            return false;
        }
    }


    //random2
    function random2(uint number) public view returns(uint256){
        uint256 getRandom1 = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao,  
        msg.sender))) % number;
        //if true, work while statement
        while(getRandom1 >= 10) {
            getRandom1 / 2;
        }
        return getRandom1;
    }

    function random3(uint number) public view returns(uint256){
        uint256 getRandom1 = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao,  
        msg.sender))) % number;

        return getRandom1;
    }


    //100으로 나눴을때는 100아래값만 나옴 0 ~ 99
    //10으로 나눴을때는 100아래값만 나옴 0 ~ 9
    function random4() public view returns(bool){
        uint256 getRandom1 = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao,  
        msg.sender))) % 10;
        if(getRandom1 > 7) {
            return true;
        }
        else {
            return false;
        }
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //burnable을 만들어서 토큰 태우기 가능
    function burn(uint256 tokenId) external virtual{
        //require(ownerOf(tokenId) == msg.sender,"fEfs");
        _burn(tokenId, true);
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