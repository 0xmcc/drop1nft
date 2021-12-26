const hre = require("hardhat");

async function main() {
  const Dye = await hre.ethers.getContractFactory("DropYourENS");
  const dye = await Dye.deploy("DropYourENS", "DYE");
  await dye.deployed();
  console.log("NFT deployed to:", dye.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
