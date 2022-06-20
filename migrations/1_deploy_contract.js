const ParticleStaking = artifacts.require('ParticleStaking');

module.exports = async (deployer) => {
  await deployer.deploy(ParticleStaking);
};
