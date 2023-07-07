
const hre = require("hardhat");


async function main() {

  let Token = await hre.ethers.getContractFactory("Token");
  Token = await Token.deploy("abc","ab",10000);

  await Token.deployed();

  console.log(
    `Token  ${Token.address}`
  );

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// 0xe836A4712b5A2765747b7674ECAD8363724F1052