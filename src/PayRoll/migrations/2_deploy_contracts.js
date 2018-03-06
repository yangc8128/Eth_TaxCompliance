var Owned = artifacts.require("Owned");
var Mutex = artifacts.require("Mutex");
var SafeMath = artifacts.require("SafeMath");
var EmploymentRecord = artifacts.require("EmploymentRecord");
//var Payment = artifacts.require("Payment");
//var PermanentPay = artifacts.require("PermanentPay");
//var CasualPay = artifacts.require("CasualPay");
//var ContractPay = artifacts.require("ContractPay");
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
  deployer.link(Owned, EmploymentRecord);//,Payment]);
  deployer.link(Mutex, EmploymentRecord);//,Payment]);
  deployer.link(SafeMath,EmploymentRecord);
  deployer.deploy(EmploymentRecord);
  //deployer.deploy(Payment);
  //deployer.deploy(PermanentPay);
  //deployer.deploy(CasualPay);
  //deployer.deploy(ContractPay);
};

// https://github.com/trufflesuite/truffle-migrate/issues/10
// Cannot find artifacts