const FoxStaking = artifacts.require('FoxStaking');

module.exports = async (deployer) => {
  await deployer.deploy(FoxStaking);
};
