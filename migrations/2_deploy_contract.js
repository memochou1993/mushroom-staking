const MushroomStaking = artifacts.require('MushroomStaking');

module.exports = async (deployer) => {
  await deployer.deploy(MushroomStaking);
};
