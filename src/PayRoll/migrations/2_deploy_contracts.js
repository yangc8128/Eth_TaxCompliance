/*
var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
};
*/
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