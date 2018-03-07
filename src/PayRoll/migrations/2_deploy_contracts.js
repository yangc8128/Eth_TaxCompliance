var Owned = artifacts.require("Owned");
var Mutex = artifacts.require("Mutex");
var SafeMath = artifacts.require("SafeMath");
var TaxAgency = artifacts.require("TaxAgency");
var FederalTaxation = artifacts.require("FederalTaxation");
var StateTaxation = artifacts.require("StateTaxation");
var EmploymentRecord = artifacts.require("EmploymentRecord");
var ConvertLib = artifacts.require("ConvertLib");
var MetaCoin = artifacts.require("MetaCoin");

module.exports = function(deployer) {
  // metacoin.js
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  // payroll.js
  // Dependencies
  deployer.deploy(Owned);
  deployer.deploy(Mutex);
  deployer.deploy(SafeMath);
  deployer.deploy(TaxAgency);
  // Linking Dependencies
  deployer.link(TaxAgency,FederalTaxation);
  deployer.link(TaxAgency,StateTaxation);
  deployer.link(Owned, EmploymentRecord);
  deployer.link(Mutex, EmploymentRecord);
  deployer.link(SafeMath,EmploymentRecord);
  // Deploying Dapp
  deployer.deploy(EmploymentRecord);
};

// https://github.com/trufflesuite/truffle-migrate/issues/10
// Cannot find artifacts