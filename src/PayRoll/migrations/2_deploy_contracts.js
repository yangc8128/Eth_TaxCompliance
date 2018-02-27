var SafeContract = artifacts.require("../../SafeContract.sol");
var SafeMath = artifacts.require("../../SafeMath.sol");
var PayRoll = artifacts.require("../contracts/PayRoll.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeContract);
  deployer.deploy(SafeMath);
  deployer.link(SafeContract,PayRoll);
  deployer.link(SafeMath,PayRoll);
  deployer.deploy(PayRoll);
};