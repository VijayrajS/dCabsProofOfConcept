const Dcabs = artifacts.require("Dcabs");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Dcabs, {from: accounts[0]});
};
