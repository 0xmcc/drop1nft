const hre = require("hardhat");

async function main() {
  const myArgs = process.argv.slice(2);
  const id = myArgs[0];
  const uri = myArgs[1];
  const Dye = await hre.ethers.getContractFactory("DropYourENS");
  const dye = Dye.attach("ethereum address here")
  try {
    await dye.setURI(id, uri)
  } catch (err) {
    console.error(err)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
