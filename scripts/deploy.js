const hre = require("hardhat");

async function main() {
  // Deploy CoolMonkeBanana contract
  const CoolMonkeBanana = await hre.ethers.getContractFactory("CoolMonkeBanana");
  const coolMonkeBanana = await CoolMonkeBanana.deploy();

  await coolMonkeBanana.deployed();

  console.log("CoolMonkeBanana deployed to:", coolMonkeBanana.address);

  // Deploy CoolMonkes contract
  const CoolMonkes = await hre.ethers.getContractFactory("CoolMonkes");
  const coolMonkes = await CoolMonkes.deploy();

  await coolMonkes.deployed();

  console.log("CoolMonkes deployed to:", coolMonkes.address);

  // Deploy Monkestake contract
  const Monkestake = await hre.ethers.getContractFactory("Monkestake");
  const monkestake = await Monkestake.deploy();

  await monkestake.deployed();

  console.log("Monkestake deployed to:", monkestake.address);

  // Deploy BoostPasses contract
  const BoostPasses = await hre.ethers.getContractFactory("BoostPasses");
  const boostPasses = await BoostPasses.deploy();

  await boostPasses.deployed();

  console.log("BoostPasses deployed to:", boostPasses.address);

  // Configure settings for Monkestake contract
  let tx;

  tx = await monkestake.setBoostAddress(boostPasses.address);
  await tx.wait();
  
  tx = await monkestake.setMonkeAddress(coolMonkes.address);
  await tx.wait();

  console.log("Boost & Monke address set");


  // Configure settings for BoostPasses contract
  tx = await boostPasses.setCMBAddress(coolMonkeBanana.address);
  await tx.wait();
  
  tx = await boostPasses.setStakeAddress(monkestake.address);
  await tx.wait();

  console.log("CBM & Stake address set");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
