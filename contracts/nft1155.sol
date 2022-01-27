// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./contentmixin.sol";

contract DropYourENS is ERC1155, ContextMixin,  Ownable {
  struct token {
    bytes32 claimMerkleRoot;
    bytes32 communitySaleMerkleRoot;
    bool isClaimListActive;
    bool isCommunitySaleActive;
    bool isPublicSaleActive;
    string uri;
    uint256 publicSalePrice;
    uint256 communitySalePrice;
    uint256 totalSupply;
    uint256 totalMinted;
    uint256 royaltyAmount; //multiply the desired percentage by * 100
    address _royaltyRecipient;

    mapping(address => bool) whitelistClaimed;
  }
  mapping(uint256 => token) public tokens;
  mapping(uint256 => address) private _royaltyRecipient;

  event PermanentURI(string _value, uint256 indexed _id);
  
  // ============ ACCESS CONTROL/SANITY MODIFIERS ============

  modifier tokenIdDoesNotExist(uint256 _id) {
    require(tokens[_id].totalSupply == 0, "TOKEN ID EXISTS");
    _;
  }
  modifier validTokenId(uint256 id) {
    require(tokens[id].totalSupply != 0, "INVALID TOKEN ID"); // double check to make sure
    _;
  }
  modifier maxPerWLValid(uint256 id) {
    require(tokens[id].totalSupply != 0, "INVALID TOKEN ID"); // double check to make sure
    _;
  }

  modifier canMintToken(uint256 id) {
    require(tokens[id].totalMinted < tokens[id].totalSupply, "MAX REACHED");
    _;
  }
  modifier validRoyaltyRecipient(address addr) {
    require(addr != address(0), "INVALID RECIPIENT");

  }

  constructor(address recipient) {  }

  function setURI(
        uint256 id, 
        uint256 totalSupply, 
        bool isClaimListActive,
        bool isCommunitySaleActive,
        bool isPublicSaleActive,
        bytes32 claimMerkleRoot, 
        bytes32 communitySaleMerkleRoot, 
        uint256 communitySalePrice, 
        uint256 publicSalePrice, 
        string calldata tokenURI,
        uint256 royaltyAmount, 
        address royaltyRecipient
  ) 
        external 
        tokenIdDoesNotExist(id)
        validRoyaltyRecipient(royaltyRecipient)
        onlyOwner 
  {
        require(totalSupply > 0, "NEED AT LEAST ONE TOKEN");
        _setURI(id, totalSupply, isClaimListActive, isCommunitySaleActive, isPublicSaleActive, claimMerkleRoot, communitySaleMerkleRoot, communitySalePrice, publicSalePrice, tokenURI, royaltyAmount, royaltyRecipient);
        
        emit URI(tokenURI, id);
        emit PermanentURI(tokenURI, id);
  }

  function setURIBatch(
      uint256[] calldata ids,
      uint256[] calldata caps,
      bool[] calldata areClaimsListsActive,
      bool[] calldata areCommunitySalesActive,
      bool[] calldata arePublicSalesActive,
      uint256[] calldata royaltyAmounts,
      address[] calldata royaltyRecipients,
      uint256[] calldata communitySalePrices,
      uint256[] calldata publicSalePrices,
      bytes32[] calldata claimMerkleRoots,
      bytes32[] calldata communitySaleMerkleRoots,
      string[] calldata uris
  ) 
      external 
      onlyOwner 
  {
      uint256 idsLength = ids.length;
      {
          uint256 capsLength = caps.length;
          uint256 areClaimsListsActiveLength = areClaimsListsActive.length;
          uint256 areCommunitySalesActiveLength = areCommunitySalesActive.length;
          uint256 arePublicSalesActiveLength = arePublicSalesActive.length;
          uint256 communitySalePricesLength = communitySalePrices.length;
          uint256 publicSalePricesLength = publicSalePrices.length;
          uint256 royaltyRecipientsLength = royaltyRecipients.length;
          uint256 royaltyAmountsLength = royaltyAmounts.length;
          uint256 claimMerkleRootsLength = claimMerkleRoots.length;
          uint256 communitySaleMerkleRootsLength = communitySaleMerkleRoots.length;
          uint256 urisLength = uris.length;
          require(capsLength == idsLength, "LENGTH_MISMATCH");
          require(capsLength == areClaimsListsActiveLength, "LENGTH_MISMATCH");
          require(capsLength == areCommunitySalesActiveLength, "LENGTH_MISMATCH");
          require(capsLength == arePublicSalesActiveLength, "LENGTH_MISMATCH");
          require(capsLength == communitySalePricesLength, "LENGTH_MISMATCH");
          require(capsLength == publicSalePricesLength, "LENGTH_MISMATCH");
          require(capsLength == claimMerkleRootsLength, "LENGTH_MISMATCH");
          require(capsLength == communitySaleMerkleRootsLength, "LENGTH_MISMATCH");
          require(capsLength == royaltyAmountsLength, "LENGTH_MISMATCH");
          require(capsLength == royaltyRecipientsLength, "LENGTH_MISMATCH");
          require(capsLength == urisLength, "LENGTH_MISMATCH");
      }
      for (uint256 i = 0; i < idsLength; ) {
          uint256 id = ids[i];
          require(tokens[id].totalSupply == 0, "TOKEN ID EXISTS");
          require(royaltyRecipients[i] != address(0), "INVALID RECIPIENT");
          _setURI(ids[i], caps[i], areClaimsListsActive[i], areCommunitySalesActive[i], arePublicSalesActive[i], claimMerkleRoots[i], communitySaleMerkleRoots[i], communitySalePrices[i], publicSalePrices[i], uris[i], royaltyAmounts[i], royaltyRecipients[i]);          
          emit URI(uris[i], id);
          emit PermanentURI(uris[i], id);
          unchecked {
            i++;
          }
      }

  }

  function setClaimlistActive(uint256 id, bool newClaimlistActive) external onlyOwner {
    tokens[id].isClaimListActive = newClaimlistActive;
  }
  function setCommunitySaleActive(uint256 id, bool newCommunitySaleActive) external onlyOwner {
    tokens[id].isCommunitySaleActive = newCommunitySaleActive;
  }
  function setPublicSaleACtive(uint256 id, bool newPublicSaleActive) external onlyOwner {
    tokens[id].isPublicSaleActive = newPublicSaleActive;
  }

  function gift(uint256 id, address[] calldata addresses) external onlyOwner {
    uint256 numToGift = addresses.length;
    require(tokens[id].totalMinted + numToGift <= tokens[id].totalSupply, "MAX REACHED");
    for (uint256 i = 0; i < numToGift; ) {
      _mint(addresses[i], id, 1, new bytes(0));
      unchecked {
        i++;
      }
    }
    tokens[id].totalMinted += numToGift;
  }

  function mint(
      uint256 id, 
      bytes32[] calldata proof
  ) 
      external 
      payable 
      validTokenId(id)
      canMintToken(id)
  {
    //require(!tokens[id].claimListClaimed[msg.sender], "ALREADY CLAIMED");
    if (tokens[id].isClaimListActive) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(proof, tokens[id].claimMerkleRoot, leaf), "INVALID PROOF");
      tokens[id].claimlistClaimed[msg.sender] = true;
    } else {
      require(msg.value == tokens[id].salePrice, "INCORRECT ETH SENT");
    }

    _mint(msg.sender, id, 1, new bytes(0));
    tokens[id].totalMinted += 1;
  }

  function uri(uint256 id) public view override returns (string memory tokenURI) {
    tokenURI = tokens[id].uri;
  }

   function _setURI(
        uint256 id, 
        uint256 totalSupply, 
        bool isClaimListActive,
        bool isCommunitySaleActive,
        bool isPublicSaleActive,
        bytes32 claimMerkleRoot, 
        bytes32 communitySaleMerkleRoot, 
        uint256 communitySalePrice, 
        uint256 publicSalePrice, 
        string calldata tokenURI,
        uint256 royaltyAmount,
        address royaltyRecipient
    ) 
          internal 
    {
        tokens[id].totalSupply = totalSupply;
        tokens[id].isClaimListActive = isClaimListActive;
        tokens[id].isCommunitySaleActive = isCommunitySaleActive;
        tokens[id].isPublicSaleActive = isPublicSaleActive;
        tokens[id].totalSupply = totalSupply;
        tokens[id].claimMerkleRoot = claimMerkleRoot;
        tokens[id].communitySaleMerkleRoot = communitySaleMerkleRoot;
        tokens[id].publicSalePrice = publicSalePrice;
        tokens[id].communitySalePrice = communitySalePrice;
        tokens[id].royaltyRecipient = royaltyRecipient;
        tokens[id].royaltyAmount = royaltyAmount;
        tokens[id].uri = tokenURI;
        tokens[id].isClaimListActive = isClaimListActive;
        tokens[id].isCommunitySaleActive = isCommunitySaleActive;
        tokens[id].isPublicSaleActive = isPublicSaleActive;
        tokens[id].claimListClaimed = [];
    }
  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(address newRecipient) internal {
    require(newRecipient != address(0), "INVALID RECIPIENT");
    _royaltyRecipient = newRecipient;
  }

  function setRoyalties(address newRecipient) external onlyOwner {
    _setRoyalties(newRecipient);
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (_royaltyRecipient, (_salePrice * tokens[tokenId].royaltyAmount) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
           interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
           interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
           interfaceId == 0x2a55205a;   // ERC165 Interface ID for ERC2981
  }

  function _msgSender() internal override view returns (address) {
    return ContextMixin.msgSender();
  }

}
