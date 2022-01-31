const hre = require("hardhat");
require('dotenv').config({ path: __dirname + '/.env' })

const { RECIPIENT } = process.env;
async function main() {
    // We receive the contract to deploy
  const [deployer] = await ethers.getSigners();

  console.log('Receiving contract');
  console.log( "Deploying contracts with the account:", deployer.address );
  console.log("Account balance:", (await deployer.getBalance()).toString());
  //Calling the ethers.js method ContractFactory. This will look for the "DropYourENS.sol" file,
  //and return an instance that we can use ContractFactory methods on.

  const Dye = await hre.ethers.getContractFactory("DropYourENS");
  console.log('Deploying NFT...');

  const dye = await Dye.deploy(RECIPIENT)
  await dye.deployed();
  console.log("NFT deployed to:", dye.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
