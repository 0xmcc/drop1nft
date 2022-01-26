const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require('keccak256');

describe("MintMax", function () {
  it("Should fail when minting more than max supply", async function () {
    [owner, ...addrs] = await ethers.getSigners();
    const Dye = await ethers.getContractFactory("DropYourENS");
    const dye = await Dye.deploy("0x1111111111111111111111111111111111111111");
    await dye.deployed();

    const leafNodes = addrs.map(wallet => keccak256(wallet.address));
    const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
    const root = merkleTree.getRoot();
    await dye.setURI(1, 2, root, "test uri");

    // test standard mint
    for (i = 0; i < 2; i++) {
      const leaf = keccak256(addrs[i].address);
      const proof1 = merkleTree.getHexProof(leaf);
      await dye.connect(addrs[i]).mint(1, proof1);
      expect(await dye.balanceOf(addrs[i].address, 1)).to.equal(1);
    }

    await expect(dye.connect(owner).mint(1, [])).to.be.revertedWith("MAX REACHED");
  });
});
