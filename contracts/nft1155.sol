// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

contract DropYourENS is ERC1155, Ownable {
  struct token {
    bytes32 rootHash;
    string uri;
    uint256 salePrice;
    uint256 totalSupply;
    uint256 totalMinted;
    bool isWhitelistPeriod;
    mapping(address => bool) whitelistClaimed;
  }
  mapping(uint256 => token) public tokens;
  address private _recipient;

  event PermanentURI(string _value, uint256 indexed _id);
  
  constructor(address recipient) {
    _recipient = recipient;
  }

  function setURI(uint256 id, uint256 totalSupply, bytes32 rootHash, uint256 salePrice, string calldata tokenURI) external onlyOwner {
    require(tokens[id].totalSupply == 0, "TOKEN ID EXISTS");
    require(totalSupply > 0, "TOKEN ID EXISTS");
    tokens[id].totalSupply = totalSupply;
    tokens[id].rootHash = rootHash;
    tokens[id].salePrice = salePrice;
    tokens[id].uri = tokenURI;
    tokens[id].isWhitelistPeriod = true;
    emit URI(tokenURI, id);
    emit PermanentURI(tokenURI, id);
  }

  function setURIBatch(
      uint256[] calldata ids,
      uint256[] calldata caps,
      uint256[] calldata salePrices,
      bytes32[] calldata rootHashes,
      string[] calldata uris) external onlyOwner {
    uint256 idsLength = ids.length;
    {
      uint256 capsLength = caps.length;
      uint256 salePricesLength = salePrices.length;
      uint256 rootHashesLength = rootHashes.length;
      uint256 urisLength = uris.length;
      require(idsLength == capsLength, "LENGTH_MISMATCH");
      require(capsLength == salePricesLength, "LENGTH_MISMATCH");
      require(salePricesLength == rootHashesLength, "LENGTH_MISMATCH");
      require(rootHashesLength == urisLength, "LENGTH_MISMATCH");
    }

    for (uint256 i = 0; i < idsLength; ) {
      uint256 id = ids[i];
      require(tokens[id].totalSupply == 0, "TOKEN ID EXISTS");
      tokens[id].totalSupply = caps[i];
      tokens[id].rootHash = rootHashes[i];
      tokens[id].salePrice = salePrices[i];
      tokens[id].uri = uris[i];
      emit URI(uris[i], id);
      emit PermanentURI(uris[i], id);
      unchecked {
        i++;
      }
    }
  }

  function endWhitelistPeriod(uint256 id) external onlyOwner {
    tokens[id].isWhitelistPeriod = false;
  }

  function giftWitches(uint256 id, address[] calldata addresses) external onlyOwner {
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

  function mint(uint256 id, bytes32[] calldata proof) external payable {
    require(tokens[id].totalSupply != 0, "INVALID TOKEN ID"); // double check to make sure
    require(!tokens[id].whitelistClaimed[msg.sender], "ALREADY CLAIMED");
    require(tokens[id].totalMinted < tokens[id].totalSupply, "MAX REACHED");

    if (tokens[id].isWhitelistPeriod) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(proof, tokens[id].rootHash, leaf), "INVALID PROOF");
      tokens[id].whitelistClaimed[msg.sender] = true;
    } else {
      require(msg.value == tokens[id].salePrice, "INCORRECT ETH SENT");
    }

    _mint(msg.sender, id, 1, new bytes(0));
    tokens[id].totalMinted += 1;
  }

  function uri(uint256 id) public view override returns (string memory tokenURI) {
    tokenURI = tokens[id].uri;
  }

  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(address newRecipient) internal {
    require(newRecipient != address(0), "INVALID RECIPIENT");
    _recipient = newRecipient;
  }

  function setRoyalties(address newRecipient) external onlyOwner {
    _setRoyalties(newRecipient);
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (_recipient, (_salePrice * 1000) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
           interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
           interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
           interfaceId == 0x2a55205a;   // ERC165 Interface ID for ERC2981
  }

}
