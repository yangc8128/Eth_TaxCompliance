/*
 * Consider: return meta.sendCoin(account_two, amount, {from: account_one});
 * From MetaCoin.sol the method is sendCoind(address, uint)
 * The added parameter in the list has modified the address, i.e. msg.sender
 */

// Used for testing in application context
var PayRoll = artifacts.require("./PayRoll.sol");

contract('PayRoll', function(accounts) {
  it("should determine owner of PayRoll", function() {
    return PayRoll.deployed.then(function(instance) {
      return instance.getOwner.call();
    }).then(function(owner) {
      assert.equal(owner, accounts[0], "First account is not owner");
    });
  });


  it("should create and map an employee ", function() {
    return PayRoll.deployed().then(function(instance) {
      instance.setEmployee.call(instance.EmploymentType.PERM,accounts[1],true,"Bob","Marley");
      return instance.accessEmployee.call(accounts[1]);
    }).then(function(activeStatus) {
      assert.equal(activeStatus, true, "Did not create employee, nor properly mapped");
    });
  });


  it("should create and map a Payment for existing employee", function() {
    return PayRoll.deployed().then(function(instance) {
      return instance.createEmployee.call(instance.owner,accounts[1],2500,2500,2500);
    }).then(function(paymentAddress) {
      assert.equal(paymentAddress, instance.paymentContracts[accounts[1]], "Payment not successfully created and mapped");
    });
  });
  it("should fail to create and map a Payment for nonexisting employee", function() {
    return PayRoll.deployed().then(function(instance) {
      return instance.createEmployee.call(instance.owner,accounts[2],2500,2500,2500);
    }).then(function(paymentAddress) {
      assert.equal(paymentAddress, instance.paymentContracts[accounts[2]], "Incorrect payment successfully created and mapped");
    });
  });
  it("should fail to create and map a Payment for nonactive employee", function() {
    return PayRoll.deployed().then(function(instance) {
      instance.updateEmployeeActiveFlag.call(account[1], false);
      return instance.createEmployee.call(instance.owner,accounts[1],2500,2500,2500);
    }).then(function(paymentAddress) {
      assert.equal(paymentAddress, instance.paymentContracts[accounts[1]], "Incorrect payment successfully created and mapped");
    });
  });


  /*
  // Attempt to timely ask for a payout on a Payment from employee
  it("should pay employee from Payment", function() {
    return PayRoll.deployed().then(function(instance) {
      return instance.paymentContracts[accounts[1]];
    }).then(function(paymentAddress) {

    });
  });
  // Attempt to prematurely payout Payment from employee
  // Attempt to prematurely payout Payment from owner
  // Attempt to prematurely payout Payment from stranger
  // Attempt to kill Payment prior to payout
  */
}); // End of contract

// Truffle JS Test Documentation: http://truffleframework.com/docs/getting_started/javascript-tests