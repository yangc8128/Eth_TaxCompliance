/*
 * Test Environment Questions:
 * How do you change the caller of a function to simulate real world use cases? [1]
 *    Consider: return meta.sendCoin(account_two, amount, {from: account_one});
 *    From MetaCoin.sol the method is sendCoind(address, uint)
 *    The added parameter in the list has modified the address, i.e. msg.sender
 * 
 * When deploying contracts at the beginning with artifacts, is it accounts[0], that does it? [5]
 *    According to the StackOverFlow, Truffle will use by default the first account in the wallet given
 *    i.e. accounts[0]. Unless told otherwise
 * 
 * How do I deploy a new contract in the contract_js test? [6] ??
 *    Just use "new contract()"
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
 * 
 * How do you test event catching? [http://truffleframework.com/docs/getting_started/contracts#catching-events]
 * 
 * Use a Contract at a specific address? [http://truffleframework.com/docs/getting_started/contracts#use-a-contract-at-a-specific-address]
 * 
 * Truffle Test Reference: http://www.zohaib.me/reusable-code-in-solidity-using-library/
 * Diving a MegaFactory into Smaller ones: https://ethereum.stackexchange.com/questions/12698/need-help-to-break-down-large-contract
 */

// Used for testing in application context
var EmploymentRecord = artifacts.require("EmploymentRecord");
var Payment = artifacts.require("Payment");

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

contract('EmploymentRecord', function(accounts) {
  it("should determine owner of PayRoll", async function() {
    let instance = await EmploymentRecord.deployed();
    let ownerAddr = await instance.getOwner.call();
    assert.equal(ownerAddr, accounts[0], "First account is not owner");
  });

  const testSetEmployee = async function (instance, type, acctID, stringTag) {
    await instance.setEmployee.call(type,acctID,true,"Bob","Marley");
    let activeStatus = await instance.accessEmployee.call(acctID);
    assert.equal(activeStatus, true, "Did not create employee, nor properly mapped for: " + stringTag);
  }
  it("should create and map an employee", async function() {
    let instance = await EmploymentRecord.deployed();
    testSetEmployee(instance, instance.EmploymentType.OWNER, accounts[0], "Owner");
    testSetEmployee(instance, instance.EmploymentType.PERM, accounts[1], "Permanent");
    testSetEmployee(instance, instance.EmploymentType.CASUAL, accounts[2], "Casual");
    testSetEmployee(instance, instance.EmploymentType.CONTRACT, accounts[3], "Contract");
  });

  // Consider making frequency just input for seconds
  var pay = 250000;
  var freq = 1;
  var endTime = 31556926;

  const testCreatePayment = async function (acctID, errorStatement) {
    let payAddr = await instance.createPayment.call(instance.owner,acctID,pay,freq,endTime);
    var createdPaymentAddr = instance.paymentContracts[acctID];
    assert.equal(payAddr, createdPaymentAddr, errorStatement);
  }
  it("should create and map a Payment for existing employee", async function() {
    let instance = await EmploymentRecord.deployed();
    testCreatePayment(accounts[1],"Payment not successfully created and mapped");
  });
  it("should fail to create and map a Payment for nonexisting employee", async function() {
    let instance = await EmploymentRecord.deployed();
    testCreatePayment(accounts[2],"Incorrect payment successfully created and mapped");
    // TODO
  });
  it("should fail to create and map a Payment for nonactive employee", async function() {
    let instance = await EmploymentRecord.deployed();
    await instance.updateEmployeeActiveFlag.call(accounts[1], false);
    testCreatePayment(accounts[1],"Incorrect payment successfully created and mapped");
    // TODO
  });


  // Requires timemachine, accounts that are not accounts[0]
  // Attempt to timely ask for a withdraw on a Payment from employee
  it("should pay employee from Payment", async function() {
    let instance = await EmploymentRecord.deployed();
    let paymentAddress = await instance.paymentContracts[accounts[1]];
    let paymentInstance = Payment.at(paymentAddress);

    var pay = paymentInstance.payPer;
    var freq = paymentInstance.freq;
    await paymentInstance.payOut.call( {from: accounts[0], value: pay} );

    // Timemachine call
      await timeTravel(freq)
      await mineBlock() // workaround for https://github.com/ethereumjs/testrpc/issues/336

    let balanceBefore = await web3.eth.getBalance(accounts[1]);
    await paymentInstance.withdraw.call( {from: acounts[1]} );
    let balanceAfter = await web3.eth.getBalance(accounts[1]);
    assert.equals(balanceBefore + pay, balanceAfter, "Payment was not successful");
  });
  // Why are these necessary? What errors will be faced? Possibly will payout anyways
  // Attempt to prematurely withdraw Payment from employee
  it("should fail to prematurely pay employee from Payment", async function() {
    let instance = await EmploymentRecord.deployed();
    let paymentAddress = await instance.paymentContracts[accounts[1]];
    let paymentInstance = Payment.at(paymentAddress);

    var pay = paymentInstance.payPer;
    await paymentInstance.payOut.call( {from: accounts[0], value: pay} );

    let balanceBefore = await web3.eth.getBalance(accounts[1]);
    await paymentInstance.withdraw.call( {from: acounts[1]} );
    let balanceAfter = await web3.eth.getBalance(accounts[1]);
    assert.equals(balanceBefore + pay, balanceAfter, "Payment was not successful");
  });

  // Attempt to prematurely withdraw Payment from owner
  it("should fail to prematurely pay wrong recipient from Payment", async function() {
    let instance = await EmploymentRecord.deployed();
    let paymentAddress = await instance.paymentContracts[accounts[1]];
    let paymentInstance = Payment.at(paymentAddress);

    var pay = paymentInstance.payPer;
    await paymentInstance.payOut.call( {from: accounts[0], value: pay} );

    let balanceBefore = await web3.eth.getBalance(accounts[0]);
    await paymentInstance.withdraw.call( {from: acounts[0]} );
    let balanceAfter = await web3.eth.getBalance(accounts[0]);
    assert.equals(balanceBefore + pay, balanceAfter, "Payment was not successful");
  });
  // Attempt to prematurely withdraw Payment from stranger
  it("should fail to prematurely pay wrong recipient from Payment", async function() {
    let instance = await EmploymentRecord.deployed();
    let paymentAddress = await instance.paymentContracts[accounts[1]];
    let paymentInstance = Payment.at(paymentAddress);

    var pay = paymentInstance.payPer;
    await paymentInstance.payOut.call( {from: accounts[0], value: pay} );

    let balanceBefore = await web3.eth.getBalance(accounts[5]);
    await paymentInstance.withdraw.call( {from: acounts[5]} );
    let balanceAfter = await web3.eth.getBalance(accounts[5]);
    assert.equals(balanceBefore + pay, balanceAfter, "Payment was not successful");
  });
  // Attempt to kill Payment prior to withdraw/payout
}); // End of contract

// [1] Truffle JS Test Documentation: http://truffleframework.com/docs/getting_started/javascript-tests
// [2] Medium Article on Truffle async / await: https://medium.com/@angellopozo/testing-solidity-with-truffle-and-async-await-396e81c54f93
// [3] StackOverFlow geth "truffle migrate": https://stackoverflow.com/questions/45618719/setting-gas-for-truffle
// [4] StackOverFlow initialize and monitor gas useage: https://stackoverflow.com/questions/47896681/accounting-for-transaction-fees-in-ethereum-contract-using-truffle+
// [5] StackOverFlow clarifications on initialization of contracts: https://ethereum.stackexchange.com/questions/20904/truffle-deploying-contract-with-ether
//  ??? [6] StackOverFlow making a new contract instance in Truffle Tests: https://stackoverflow.com/questions/46101430/proper-use-of-artifacts-require