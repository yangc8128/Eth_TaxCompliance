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
 * Return values on transactions vs calls?
 *    No you cannot recieve return values from transactions, only contracts see those.
 *    Only calls have accessible return values to non-contracts.
*     https://ethereum.stackexchange.com/questions/16291/truffle-call-that-returns-contract-is-returning-tx
 * 
 * Truffle Test Reference: http://www.zohaib.me/reusable-code-in-solidity-using-library/
 * Diving a MegaFactory into Smaller ones: https://ethereum.stackexchange.com/questions/12698/need-help-to-break-down-large-contract
 */

// https://github.com/babel/babel/issues/5085 <IS THE FIX>
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

// https://github.com/babel/babel-loader/issues/484
// https://javascript.info/async-await
contract('EmploymentRecord', function(accounts) {
  // PASSED
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

  /*
  const testCreatePayment = async function(instance, acctID, errorStatement) {
    // Active Employee Check
    //let activeStatus = await instance.accessEmployee.call(acctID);
    //assert.equal(activeStatus.valueOf(), true, "Non-existent employee");

    // Creating Payment
    var countBefore = await instance.getPaymentContractsCount.call();
    await instance.createPayment(acctID);
    var countAfter = await instance.getPaymentContractsCount.call();
    console.log(countAfter.valueOf());
    console.log((++countBefore).valueOf());
    assert.equal(countAfter.valueOf(), countBefore.valueOf(), errorStatement);
  }*/
  it("6 should create and map a Payment for existing employee", async function() {
    let instance = await EmploymentRecord.deployed();
    //testCreatePayment(instance, accounts[1],"Payment not successfully created and mapped");

    var countBefore = await instance.getPaymentContractsCount.call();
    await instance.createPayment(accounts[1]);
    var countAfter = await instance.getPaymentContractsCount.call();
    assert.equal(countAfter.valueOf(), (++countBefore).valueOf(), "Payment not successfully created and mapped");
  });
  it("7 should fail to create and map a Payment for nonexisting employee", async function() {
    let instance = await EmploymentRecord.deployed();
    //testCreatePayment(accounts[5],"Incorrect payment successfully created and mapped");

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
    //testCreatePayment(accounts[1],"Incorrect payment successfully created and mapped");
  });
/*

  // Requires timemachine, accounts that are not accounts[0]
  // Attempt to timely ask for a withdraw on a Payment from employee
  it("9 should pay employee from Payment", async function() {
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
  */
  // Attempt to kill Payment prior to withdraw/payout
}); // End of contract

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

// [1] Truffle JS Test Documentation: http://truffleframework.com/docs/getting_started/javascript-tests
// [2] Medium Article on Truffle async / await: https://medium.com/@angellopozo/testing-solidity-with-truffle-and-async-await-396e81c54f93
// [3] StackOverFlow geth "truffle migrate": https://stackoverflow.com/questions/45618719/setting-gas-for-truffle
// [4] StackOverFlow initialize and monitor gas useage: https://stackoverflow.com/questions/47896681/accounting-for-transaction-fees-in-ethereum-contract-using-truffle+
// [5] StackOverFlow clarifications on initialization of contracts: https://ethereum.stackexchange.com/questions/20904/truffle-deploying-contract-with-ether
//  ??? [6] StackOverFlow making a new contract instance in Truffle Tests: https://stackoverflow.com/questions/46101430/proper-use-of-artifacts-require