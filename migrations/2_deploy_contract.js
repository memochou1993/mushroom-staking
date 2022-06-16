const CastleStaking = artifacts.require('CastleStaking');

module.exports = async (deployer) => {
  await deployer.deploy(CastleStaking);
};
