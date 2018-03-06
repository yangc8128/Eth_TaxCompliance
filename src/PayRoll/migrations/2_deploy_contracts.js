var Owned = artifacts.require("Owned");
var Mutex = artifacts.require("Mutex");
var SafeMath = artifacts.require("SafeMath");
var EmploymentRecord = artifacts.require("EmploymentRecord");
var EmployeeMap = artifacts.require("EmployeeMap");
var PaymentContractMap = artifacts.require("PaymentContractMap")

var ConvertLib = artifacts.require("ConvertLib");
var MetaCoin = artifacts.require("MetaCoin");

module.exports = function(deployer) {
  // metacoin.js
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  // payroll.js
  deployer.deploy(Owned);
  deployer.deploy(Mutex);
  deployer.deploy(SafeMath);
  deployer.link(Owned, EmploymentRecord);
  deployer.link(Mutex, EmploymentRecord);
  deployer.link(SafeMath,EmploymentRecord);
  deployer.link(EmployeeMap, EmploymentRecord);
  deployer.link(PaymentContractMap, EmploymentRecord);
  deployer.deploy(EmploymentRecord);
};

// https://github.com/trufflesuite/truffle-migrate/issues/10
// Cannot find artifacts