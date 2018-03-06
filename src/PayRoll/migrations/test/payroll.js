/*
 * Truffle Test Reference: http://www.zohaib.me/reusable-code-in-solidity-using-library/
 * Diving a MegaFactory into Smaller ones: https://ethereum.stackexchange.com/questions/12698/need-help-to-break-down-large-contract
 */

import 'babel-polyfill';
//import './app';

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
  it("1 should determine owner of PayRoll", async function() {
    let instance = await EmploymentRecord.deployed();
    let ownerAddr = await instance.owner.call();
    assert.equal(ownerAddr, accounts[0], "First account is not owner");
  });


  const testSetEmployee = async function (type, acctID, stringTag) {
    let instance = await EmploymentRecord.deployed();
    await instance.setEmployee(type,acctID,"Bob","Marley");
    let activeStatus = await instance.accessEmployee.call(acctID);
    assert.equal(activeStatus, true, "Did not create employee, nor properly mapped for: " + stringTag);
  }
  it("2 should create and map owner", async function() {
    testSetEmployee(0, accounts[0], "Owner");
  });
  it("3 should create and map permanent employee", async function() {
    testSetEmployee(1, accounts[1], "Permanent");
  });
  it("4 should create and map casual employee", async function() {
    testSetEmployee(2, accounts[2], "Casual");
  });
  it("5 should create and map contract employee", async function() {
    testSetEmployee(3, accounts[3], "Contract");
  });

  // Consider making frequency just input for seconds
  //var pay = 250000;
  //var freq = 1;
  //var endTime = 31556926;

  it("6 should create and map a Payment for existing employee", async function() {
    let instance = await EmploymentRecord.deployed();

    var countBefore = await instance.getPaymentContractsCount.call();
    await instance.createPayment(accounts[1]);
    var countAfter = await instance.getPaymentContractsCount.call();
    assert.equal(countAfter.valueOf(), (++countBefore).valueOf(), "Payment not successfully created and mapped");
  });
  // Force Failed Tests
/*
  it("7 should fail to create and map a Payment for nonexisting employee", async function() {
    let instance = await EmploymentRecord.deployed();

    // Active Employee Check
    let activeStatus = await instance.accessEmployee.call(accounts[5]);
    assert.notEqual(activeStatus.valueOf(), false, "Non-existent employee");

    var countBefore = await instance.getPaymentContractsCount.call();
    await instance.createPayment(accounts[5]);
    var countAfter = await instance.getPaymentContractsCount.call();
    assert.notEqual(countAfter.valueOf(), (++countBefore).valueOf(), "Incorrect payment successfully created and mapped");
  });
  it("8 should fail to create and map a Payment for nonactive employee", async function() {
    let instance = await EmploymentRecord.deployed();
    await instance.updateEmployeeActiveFlag(accounts[1], false);

    // Active Employee Check
    let activeStatus = await instance.accessEmployee.call(accounts[1]);
    assert.notEqual(activeStatus.valueOf(), false, "Account is still active");
  });
*/


  // Requires timemachine, accounts that are not accounts[0]
  // Attempt to timely ask for a withdraw on a Payment from employee
  it("9 should pay employee from Payment", async function() {
    let instance = await EmploymentRecord.deployed();

    let paymentAddress = await instance.paymentContracts.call(accounts[1]);
    let paymentInstance = Payment.at(paymentAddress);

    let pay = await paymentInstance.payPer.call();
    let freq = await paymentInstance.freq.call();

    let balanceOwnerBefore = await web3.eth.getBalance(paymentAddress);
    await paymentInstance.payout( {from: accounts[0], value: pay.valueOf()} );
    let balanceOwnerAfter = await web3.eth.getBalance(paymentAddress);
    assert.notEqual(balanceOwnerAfter.valueOf(), balanceOwnerBefore.valueOf(), "Owner payout was not successful");

    // Timemachine call
    //await timeTravel(freq.valueOf());
    //await mineBlock(); // workaround for https://github.com/ethereumjs/testrpc/issues/336

    let balanceBefore = await web3.eth.getBalance(accounts[1]);
    await paymentInstance.withdraw( {from: accounts[1]} );
    let balanceAfter = await web3.eth.getBalance(accounts[1]);
    assert.notEqual(balanceBefore.valueOf(), balanceAfter.valueOf(), "Payment was not successful");
  }); // TODO: TIMEMACHINE IS COMMENTED OUT
  /*
  // Why are these necessary? What errors will be faced? Possibly will payout anyways
  // Attempt to prematurely withdraw Payment from employee
  it("10 should fail to prematurely pay employee from Payment", async function() {
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
  it("11 should fail to prematurely pay to Owner from Payment", async function() {
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
  it("12 should fail to prematurely pay wrong recipient from Payment", async function() {
    let instance = await EmploymentRecord.deployed();
    let paymentAddress = await instance.paymentContracts[accounts[1]];
    let paymentInstance = Payment.at(paymentAddress);

    var pay = paymentInstance.payPer;
    await paymentInstance.payOut.call( {from: accounts[0], value: pay} );

    let balanceBefore = await web3.eth.getBalance(accounts[5]);
    await paymentInstance.withdraw.call( {from: acounts[5]} );
    let balanceAfter = await web3.eth.getBalance(accounts[5]);
    assert.equals(balanceBefore + pay, balanceAfter, "Payment was successful");
  });
  // Attempt to kill Payment prior to withdraw/payout
  */
});

/*
  Errors:
  - Uncaught ReferenceError: regeneratorRuntime is not defined // 
  - no events were emitted // enums are not supported in ABI
  - 1) Contract: EmploymentRecord should create and map owner:
       AssertionError: whoop: expected { Object (s, e, ...) } to equal 1
      // ___.valueOf();
  - Test "2 should create and map owner" not making any changes onto the blockchain
      Not showing any changes when accessed.
      // <call>.call() is a call and does not change the blockchain
      // <transaction>() is a transaction and does change the blockchain
  - truffle Error: VM Exception while processing transaction: revert
      // Forgotten to make the testSetEmployee modular again, and the second call to it in Test 3 failed it
      // It means a revert was called within the contract code
 */