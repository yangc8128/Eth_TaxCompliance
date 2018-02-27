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
      instance.setEmployee(instance.EmploymentType.PERM,accounts[1],true,"Bob","Marley");
      return instance.accessEmployee(accounts[1]);
    }).then(function(activeStatus) {
      assert.equal(activeStatus, true, "Created employee, and sucessfully mapped");
    });
  });


  /*
  it("should create and map a Payment for existing employee", function() {

  });
  it("should fail to create and map a Payment for nonexisting employee", function() {

  });
  it("should fail to create and map a Payment for nonactive employee", function() {

  });
  */

  /*
  // Attempt to prematurely payout Payment from employee
  // Attempt to prematurely payout Payment from owner
  // Attempt to prematurely payout Payment from stranger
  // Attempt to kill Payment prior to payout
  */
}); // End of contract