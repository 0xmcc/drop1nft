pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DropYourENS is ERC1155, EIP712, IERC2981, Ownable {
  mapping(uint256 => string) uris;

  bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver, uint256 id");

  address public immutable _signer;

  address private _recipient;
  
  constructor(address signer, address recipient) EIP712("DropYourENS", "1") {
    _signer = signer;
    _recipient = recipient;
  }

  function setURI(uint256 id, string memory tokenURI) external onlyOwner {
    uris[id] = tokenURI;
    emit URI(tokenURI, id);
  }

  function setURIBatch(uint256[] memory ids, string[] memory tokenURIs) external onlyOwner {
    uint256 idsLength = ids.length;
    uint256 tokenURIsLength = tokenURIs.length;
    require(idsLength == tokenURIsLength, "LENGTH_MISMATCH");
    for (uint256 i = 0; i < idsLength; ) {
      uint256 id = ids[i];
      uris[id] = tokenURIs[i];
      emit URI(tokenURIs[i], id);
      unchecked {
        i++;
      }
    }
  }

  function mint(uint256 id, uint8 v, bytes32 r, bytes32 s) external {
    require(bytes(uris[id]).length != 0, "INVALID TOKEN ID"); // double check to make sure
    bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
      ECDSA.toTypedDataHash(_domainSeparatorV4(),
      keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, id))
    )));
    require(ecrecover(digest, v, r, s) == _signer, "DropYourENS: Invalid signer");
    _mint(msg.sender, id, 1, new bytes(0));
  }

  function uri(uint256 id) public view override returns (string memory tokenURI) {
    tokenURI = uris[id];
  }

  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(address newRecipient) internal {
    require(newRecipient != address(0), "Royalties: new recipient is the zero address");
    _recipient = newRecipient;
  }

  function setRoyalties(address newRecipient) external onlyOwner {
    _setRoyalties(newRecipient);
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount)
  {
    return (_recipient, (_salePrice * 1000) / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
      return
          interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
          interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
          interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
          interfaceId == 0x2a55205a;   // ERC165 Interface ID for ERC2981
  }

}
