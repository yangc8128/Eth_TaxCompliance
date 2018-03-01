/*
 * Test Environment Questions:
 * How do you change the caller of a function to simulate real world use cases? [1]
 *    Consider: return meta.sendCoin(account_two, amount, {from: account_one});
 *    From MetaCoin.sol the method is sendCoind(address, uint)
 *    The added parameter in the list has modified the address, i.e. msg.sender
 * 
 * When deploying contracts at the beginning with artifacts, is it accounts[0], that does it?
 * 
 * How do I deploy a new contract in the contract_js test?
 * 
 * Do asynchronous tests run in parallel grouped via "it()"? [2]
 *    Works off of the pair of await and a promise function such as ___.cal()
 *    Error with async, needs to be wrapped with a try/catch
 * 
 * How do I simulate time passing? [2]
 *    ____use evm_increaseTime____
 *    // Example for preparing time manipulation:
      const timeTravel = function (time) {
        return new Promise((resolve, reject) => {
          web3.currentProvider.sendAsync({
            jsonrpc: "2.0",
            method: "evm_increaseTime",
            params: [time], // 86400 is num seconds in day
            id: new Date().getTime()
          }, (err, result) => {
            if(err){ return reject(err) }
            return resolve(result)
          });
        })
      }
 *    // Example for using time manipulation:
      it("should successfully call specialFn because enough time passed", async function () {
        let meta = await MetaCoin.new();
        await timeTravel(86400 * 3) //3 days later
        await mineBlock() // workaround for https://github.com/ethereumjs/testrpc/issues/336
        let status = await meta.specialFn.call();
        assert.equal(status, true, "specialFn should be callable after 1 day")
      })
 *
 * How do I initialize a Payment with appropriate endTimes? [2]
 *    utilize number in uints of seconds for time (86400 secs = 1 days)
 *
 * How do I initialize a Payment with appropriate ether to $, without fiat transactions? [4]
 *    // Added the correct account, and the gas to go with it
 *    return instance.run({from: accounts[1], gasPrice: gasPrice});
 */

// Used for testing in application context
var PayRoll = artifacts.require("./PayRoll.sol");

// Helper Test Function
const timeTravel = function (time) {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [time], // 86400 is num seconds in day
      id: new Date().getTime()
    }, (err, result) => {
      if(err){ return reject(err) }
      return resolve(result)
    });
  })
}

contract('PayRoll', function(accounts) {
  it("should determine owner of PayRoll", function() {
    return PayRoll.deployed.then(function(instance) {
      return instance.getOwner.call();
    }).then(function(owner) {
      assert.equal(owner, accounts[0], "First account is not owner");
    });
  });


  it("should create and map an employee", function() {
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
  // Requires timemachine
  // Attempt to timely ask for a payout on a Payment from employee
  it("should pay employee from Payment", function() {
    let payroll = await PayRoll.deployed();
    let paymentAddress = await payroll.paymentContracts[accounts[1]];

    // TODO
    });
  });
  // Attempt to prematurely payout Payment from employee
  // Attempt to prematurely payout Payment from owner
  // Attempt to prematurely payout Payment from stranger
  // Attempt to kill Payment prior to payout
  */
}); // End of contract

// [1] Truffle JS Test Documentation: http://truffleframework.com/docs/getting_started/javascript-tests
// [2] Medium Article on Truffle async / await: https://medium.com/@angellopozo/testing-solidity-with-truffle-and-async-await-396e81c54f93
// [3] StackOverFlow geth "truffle migrate": https://stackoverflow.com/questions/45618719/setting-gas-for-truffle
// [4] StackOverFlow initialize and monitor gas useage: https://stackoverflow.com/questions/47896681/accounting-for-transaction-fees-in-ethereum-contract-using-truffle