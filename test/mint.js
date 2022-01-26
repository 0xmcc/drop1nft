const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require('keccak256');

describe("Mint", function () {
  it("Should allow whitelisted address to claim", async function () {
    [owner, ...addrs] = await ethers.getSigners();
    const Dye = await ethers.getContractFactory("DropYourENS");
    const dye = await Dye.deploy("0x1111111111111111111111111111111111111111");
    await dye.deployed();

    const leafNodes = addrs.map(wallet => keccak256(wallet.address));
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
    const root = merkleTree.getRoot();
    await dye.setURI(1, addrs.length, root, "test uri");
    expect(await dye.uri(1)).to.equal("test uri");

    // test minting twice
    await expect(dye.setURI(1, 10, root, "test uri")).to.be.revertedWith("TOKEN ID EXISTS");

    // test non whitelisted address can't claim
    const invalidProof = [
      "0x1111111111111111111111111111111111111111111111111111111111111111",
      "0x1111111111111111111111111111111111111111111111111111111111111111",
    ]
    await expect(dye.mint(1, invalidProof)).to.be.revertedWith("INVALID PROOF");

    // test standard mint
    for (const wallet of addrs) {
      const leaf = keccak256(wallet.address);
      const proof1 = merkleTree.getHexProof(leaf);
      await dye.connect(wallet).mint(1, proof1);
      expect(await dye.balanceOf(wallet.address, 1)).to.equal(1);
      await expect(dye.connect(wallet).mint(1, proof1)).to.be.revertedWith("ALREADY CLAIMED");
    }
  });
});
