// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // ERC2981 NFT Royalty Standard

/**
    (                                                                        
    )\ )                   )        (                                        
    (()/(      )         ( /(   (    )\ )  (             )                (   
    /(_))  ( /(   (     )\()) ))\  (()/(  )\   (     ( /(   (      (    ))\  
    (_))_   )(_))  )\ ) (_))/ /((_)  /(_))((_)  )\ )  )(_))  )\ )   )\  /((_) 
    |   \ ((_)_  _(_/( | |_ (_))   (_) _| (_) _(_/( ((_)_  _(_/(  ((_)(_))   
    | |) |/ _` || ' \))|  _|/ -_)   |  _| | || ' \))/ _` || ' \))/ _| / -_)  
    |___/ \__,_||_||_|  \__|\___|   |_|   |_||_||_| \__,_||_||_| \__| \___|  
 */
contract DanteNFT is ERC721Enumerable, ERC721Burnable, ERC2981, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    mapping (address => uint) public claimWhitelist;

    string public provenance;

    uint256 public claimTimestampEnd;
    uint256 public revealTimestamp;

    uint256 public saleStart;

    uint256 public constant MAX_ELEMENTS = 11;
    uint256 public constant PRICE = 100 wei;
    uint256 public constant MAX_BY_MINT = 3;
    uint256 public constant WHITELIST_CLAIM_WINDOW = 1 hours;
    uint256 public constant PUBLIC_WINDOW = 1 hours;
    uint256 public constant RESERVED = 1;
    uint96 public constant ROYALTY_FEES = 500;

    address public dao;
    
    string public baseTokenURI;

    bool public saleOpen = false;
    bool public canChangeURI = true;
    bool public canChangeProv = true;
    bool public mintedReserved = false;

    event CreateDante(uint256 indexed id);

    constructor(address _dao, string memory _provenance) ERC721("Dantes", "DANTES") {
        dao = _dao;
        provenance = _provenance;
        // 3% royalty fees to our DAO fund
        _setDefaultRoyalty(dao, ROYALTY_FEES);
    }

    modifier saleIsOpen {
        // check total minted nfts is lower than max allowed
        require(_totalSupply() < MAX_ELEMENTS, "Sale end");
        // time has to be before reveal
        require(block.timestamp < revealTimestamp, "Sale end");
        // sale is set to true
        require(saleOpen, "Sale not open");
        
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    // reserve nfts for giveaways etc
    function reservedMint() public onlyOwner {
        address minter = msg.sender;

        require(mintedReserved == false, "Reserved NFTs already minted.");

        // mint the required NFTs
        for (uint256 i = 0; i < RESERVED; i++) {
            _mintAnElement(minter);
        }

        mintedReserved = true;
    }

    // public mints
    function publicMint(uint256 _count) public payable saleIsOpen {
        // check we are now longer in whitelist time window
        require(block.timestamp > claimTimestampEnd, "Sale is not public yet");

        // NFTs will go to who called the function
        address minter = msg.sender;
        
        // get the amount of NFTs minted until now
        uint256 total = _totalSupply();

        // check minter sent enough funds
        uint256 totalPrice = price(_count);
        require(msg.value >= totalPrice, "Not enough funds");

        // check that adding the nfts won't go above our max supply
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        
        // can't mint more than MAX_BY_MINT at a time
        require(_count <= MAX_BY_MINT, "Can't mint these many at once");
        
        // mint the required NFTs
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(minter);
        }
    }
    
    // whitelisted mints
    function whitelistMint() public payable saleIsOpen {
        // NFTs will go to who called the function
        address minter = msg.sender;
        
        // get the amount of whitelisted nfts
        uint256 totalToMint = claimWhitelist[minter];

        // check sender has whitelisted nfts
        require(totalToMint > 0, "Address not whitelisted");
        
        // check we are in whitelist time window
        require(block.timestamp <= claimTimestampEnd, "Claim window has expired");
        
        // check enough funds were sent
        uint256 totalPrice = price(totalToMint);
        require(msg.value >= totalPrice, "Value below price");

        // mint the required nfts
        for (uint256 i = 0; i < totalToMint; i++) {
            _mintAnElement(minter);
        }

        // update whitelist
        claimWhitelist[minter] = 0;
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _safeMint(_to, id);
        _tokenIdTracker.increment();

        emit CreateDante(id);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // update royalty info
    function setRoyaltyInfo(address _receiver, uint96 _fee) public onlyOwner {
        _setDefaultRoyalty(_receiver, _fee);
    }

    // permanently revoke ability to change URI
    function revokeSetURIAbility() public onlyOwner {
        canChangeURI = false;
    }

    // permanently revoke ability to change prov
    function revokeSetProvAbility() public onlyOwner {
        canChangeProv = false;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(canChangeURI, "Ability to change URI was revoked");
        baseTokenURI = baseURI;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenance) public onlyOwner {
        require(canChangeProv, "Ability to change provenance hash was revoked");
        provenance = _provenance;
    }

    function flipSaleStatus() public onlyOwner {
        saleOpen = !saleOpen;
    }

    function startSale() public onlyOwner {
        require(saleStart == 0, "cant re-start initial sale");
        
        saleStart = block.timestamp;
        saleOpen = true;
        claimTimestampEnd = saleStart + WHITELIST_CLAIM_WINDOW;
        revealTimestamp = saleStart + WHITELIST_CLAIM_WINDOW + PUBLIC_WINDOW;
    }

    // withdraw all funds to dao wallet
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = dao.call{value: balance}("");
        require(success, "Transfer failed.");
    }
    
    // add whitelist addresses
    function addBatchToWhitelist(address[] memory addrs, uint[] memory quantity) public onlyOwner {
        require(addrs.length == quantity.length, "Addrs and quantity should have the same number of elements");

        for (uint256 i = 0; i < addrs.length; i++) {
            claimWhitelist[addrs[i]] = quantity[i];
        }
    }
    
    function addToWhitelist(address addr, uint256 quantity) public onlyOwner {
        claimWhitelist[addr] = quantity;
    }

    // remove from whitelist
    function removeFromWhitelist(address addr) public onlyOwner {
        claimWhitelist[addr] = 0;
    }
}