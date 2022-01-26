const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MockProvider } = require("ethereum-waffle");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require('keccak256');


describe("Mint", function () {
  it("Should allow whitelisted address to claim", async function () {
    const Dye = await ethers.getContractFactory("DropYourENS");
    const dye = await Dye.deploy("0x0000000000000000000000000000000000000001");
    await dye.deployed();

    const provider = new MockProvider();
    const wallets = provider.getWallets();
    const leafNodes = wallets.map(wallet => keccak256(wallet.address));
    const merkleTree = new MerkleTree(leafNodes, keccak256);
    const root = merkleTree.getRoot();
    await dye.setURI(1, 100, root, "test uri");

    // test minting test
    // await expect(dye.setURI(1, 100, root, "test uri")).to.be.revertedWith("TOKEN ID EXISTS");

    // test non whitelisted address can't claim
    // const invalidProof = [
    //   "0x1111111111111111111111111111111111111111111111111111111111111111",
    //   "0x1111111111111111111111111111111111111111111111111111111111111111",
    // ]
    // await expect(dye.mint(1, invalidProof)).to.be.revertedWith("INVALID PROOF");

    const addr = wallets[1].address;
    const leaf = keccak256(addr);
    const proof1 = merkleTree.getHexProof(leaf);
    const dye1 = dye.connect(wallets[1]);
    const tx = await dye1.populateTransaction.mint(1, proof1);
    console.log(tx.data);
    // await expect(dye.connect(wallets[1]).mint(1, proof1, {gasLimit: 1500000})).to.be.revertedWith("ALREADY CLAIMED");
    // await dye.balanceOf(addr, 1)

    // test same address can't claim twice

  });
});
