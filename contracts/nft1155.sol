// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./contentmixin.sol";

contract DropYourENS is ERC1155, ContextMixin,  Ownable {
  struct token {
    bytes32 claimMerkleRoot;
    bool isClaimListActive;
    string uri;
    uint256 communitySalePrice;
    uint256 totalSupply;
    uint256 totalMinted;
  }
  mapping(address => bool) claimListClaimed; 
  mapping(uint256 => token) public tokens;
  mapping(uint256 => address) private _royaltyRecipient;

  event PermanentURI(string _value, uint256 indexed _id);
  
  // ============ ACCESS CONTROL/SANITY MODIFIERS ============

  modifier tokenIdDoesNotExist(uint256 id) {
    require(tokens[id].totalSupply == 0, "TOKEN ID EXISTS");
    _;
  }
  modifier validTokenId(uint256 id) {
    require(tokens[id].totalSupply != 0, "INVALID TOKEN ID"); // double check to make sure
    _;
  }
  

  modifier canMintToken(uint256 id) {
    require(tokens[id].totalMinted < tokens[id].totalSupply, "MAX REACHED");
    _;
  }
  modifier hasNotClaimedToken() {
    require(claimListClaimed[msg.sender] != true, "User has already minted token");
    _;
  }

  modifier validRoyaltyRecipient(address addr) {
    require(addr != address(0), "INVALID RECIPIENT");
    _;
  }
  modifier claimListActive(uint256 id) {
    require(tokens[id].isClaimListActive, "Claim list is not open");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
        MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(msg.sender))
        ),
        "Address does not exist in list"
    );
    _;
  }

  constructor(address recipient) {  }

  function setURI(
        uint256 id, 
        uint256 totalSupply, 
        bool isClaimListActive,
        bytes32 claimMerkleRoot, 
        uint256 communitySalePrice, 
        string calldata tokenURI,
        address royaltyRecipient
  ) 
        external 
        tokenIdDoesNotExist(id)
        validRoyaltyRecipient(royaltyRecipient)
        onlyOwner 
  {
        require(totalSupply > 0, "NEED AT LEAST ONE TOKEN");
        tokens[id].totalMinted = 0;
        tokens[id].totalSupply = totalSupply;
        tokens[id].isClaimListActive = isClaimListActive;
        tokens[id].claimMerkleRoot = claimMerkleRoot;
        tokens[id].communitySalePrice = communitySalePrice;
        tokens[id].uri = tokenURI;
        _royaltyRecipient[id] = royaltyRecipient;
        emit URI(tokenURI, id);
        emit PermanentURI(tokenURI, id);
  }

  function setClaimlistActive(uint256 id, bool newClaimlistActive) external onlyOwner {
    tokens[id].isClaimListActive = newClaimlistActive;
  }


    // ============ PUBLIC FUNCTION FOR MINTING ============


   function mint(
      uint256 id,
      bytes32[] calldata proof
  ) 
      external 
      payable 
      validTokenId(id)
      canMintToken(id)
      hasNotClaimedToken()
      isValidMerkleProof(proof, tokens[id].claimMerkleRoot)

  {
    if (tokens[id].isClaimListActive) {
        claimListClaimed[msg.sender] = true;
    } else {
      require(msg.value == tokens[id].communitySalePrice, "INCORRECT ETH SENT");
    }

    _mint(msg.sender, id, 1, new bytes(0));
    tokens[id].totalMinted += 1;
  }

  function uri(uint256 id) public view override returns (string memory tokenURI) {
    tokenURI = tokens[id].uri;
  }

  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(uint256 id, address newRecipient) internal validRoyaltyRecipient(newRecipient) validTokenId(id)  {
    _royaltyRecipient[id] = newRecipient;
  }

  function setRoyalties(uint256 id,address newRecipient) external onlyOwner {
    _setRoyalties(id, newRecipient);
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (_royaltyRecipient[tokenId], (_salePrice * 690) / 10000);
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

 