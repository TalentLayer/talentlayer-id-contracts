import { ethers } from "hardhat";
import talentLayerContractsAdresses from "../../talent.config_localhost.json";

async function main() {
  const [alice, bob, carol] = await ethers.getSigners();
  console.log({ alice: alice.address, bob: bob.address, carol: carol.address });

  const tlID = await ethers.getContractAt(
    "TalentLayerID",
    talentLayerContractsAdresses.talentLayerID
  );

  console.log(
    "eveything is working fine the TalentLayer Adress is",
    talentLayerContractsAdresses.talentLayerID
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
