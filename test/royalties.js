const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Royalties", function () {
  it("Should return the new recipient once it's changed", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const Dye = await ethers.getContractFactory("DropYourENS");
    const dye = await Dye.deploy("0x0000000000000000000000000000000000000001");
    await dye.deployed();

    expect(await dye.owner()).to.equal(owner.address);
    expect((await dye.royaltyInfo(0, 0))[0]).to.equal("0x0000000000000000000000000000000000000001");

    const setRoyaltiesTx = await dye.setRoyalties("0x0000000000000000000000000000000000000002");
    await setRoyaltiesTx.wait();

    expect((await dye.royaltyInfo(0, 0))[0]).to.equal("0x0000000000000000000000000000000000000002");

    await expect(dye.connect(addr1).setRoyalties("0x0000000000000000000000000000000000000002")).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
