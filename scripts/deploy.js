
const hre = require("hardhat");


async function main() {

  let Token = await hre.ethers.getContractFactory("WhiteHatDAOToken");
  Token = await Token.deploy();

  await Token.deployed();

  console.log(
    `WhiteHatDAOToken  ${Token.address}`
  );

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

