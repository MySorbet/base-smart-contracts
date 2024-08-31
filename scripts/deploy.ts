import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const usdcAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e"; // Replace with actual USDC address
  const treasuryAddress = "0x8aA95723401937F2E2772beFc762d47EC256DBA5"; // Replace with actual treasury address

  try {
    const FreelanceEscrow = await ethers.getContractFactory("FreelanceEscrow");
    console.log("Contract factory obtained.");

    const freelanceEscrow = await FreelanceEscrow.deploy(usdcAddress, treasuryAddress);
    console.log("Deployment transaction sent.");

    if (!freelanceEscrow.deployTransaction) {
      throw new Error("Deployment transaction is undefined. Deployment might have failed.");
    }

    await freelanceEscrow.deployTransaction.wait(); // Wait for the deployment transaction to be mined
    console.log("FreelanceEscrow deployed to:", freelanceEscrow.address);
  } catch (error) {
    console.error("Error during contract deployment:", error);
  }
}

main().catch((error) => {
  console.error("Error in deployment script:", error);
  process.exitCode = 1;
});