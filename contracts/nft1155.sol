pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

contract DropYourENS is ERC1155, Ownable {
  mapping(uint256 => string) public uris;
  mapping(uint256 => bytes32) public rootHashes;
  mapping(address => bool) public whitelistClaimed;
  mapping(uint256 => uint256) public totalSupply;
  mapping(uint256 => uint256) public totalMinted;
  address private _recipient;

  event PermanentURI(string _value, uint256 indexed _id);
  
  constructor(address recipient) {
    _recipient = recipient;
  }

  function setURI(uint256 id, uint256 hardcap, bytes32 rootHash, string calldata tokenURI) external onlyOwner {
    require(bytes(uris[id]).length == 0, "TOKEN ID EXISTS");
    uris[id] = tokenURI;
    totalSupply[id] = hardcap;
    rootHashes[id] = rootHash;
    emit URI(tokenURI, id);
    emit PermanentURI(tokenURI, id);
  }

  function setURIBatch(uint256[] calldata ids, uint256[] calldata hardcap, bytes32[] calldata rootHash, string[] calldata tokenURIs) external onlyOwner {
    uint256 idsLength = ids.length;
    uint256 tokenURIsLength = tokenURIs.length;
    uint256 hardcapLength = hardcap.length;
    uint256 rootHashLength = rootHash.length;
    require(idsLength == tokenURIsLength, "LENGTH_MISMATCH");
    require(tokenURIsLength == hardcapLength, "LENGTH_MISMATCH");
    require(hardcapLength == rootHashLength , "LENGTH_MISMATCH");

    for (uint256 i = 0; i < idsLength; ) {
      uint256 id = ids[i];
      require(bytes(uris[id]).length == 0, "TOKEN ID EXISTS");
      uris[id] = tokenURIs[i];
      totalSupply[id] = hardcap[i];
      rootHashes[id] = rootHash[i];
      emit URI(tokenURIs[i], id);
      emit PermanentURI(tokenURIs[i], id);
      unchecked {
        i++;
      }
    }
  }

  function mint(uint256 id, bytes32[] calldata proof) external {
    require(bytes(uris[id]).length != 0, "INVALID TOKEN ID"); // double check to make sure
    require(totalMinted[id] < totalSupply[id], "MAX REACHED");
    require(!whitelistClaimed[msg.sender], "ALREADY CLAIMED");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proof, rootHashes[id], leaf), "INVALID PROOF");
    // _mint(msg.sender, id, 1, new bytes(0));

    // whitelistClaimed[msg.sender] = true;
    totalMinted[id] += 1;
  }

  function uri(uint256 id) public view override returns (string memory tokenURI) {
    tokenURI = uris[id];
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
