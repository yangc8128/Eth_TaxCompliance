import 'babel-polyfill';
//import './app';

// Used for testing in application context
var EmploymentRecord = artifacts.require("EmploymentRecord");
var Payment = artifacts.require("Payment");
var TaxAgency = artifacts.require("TaxAgency");
var TaxReport = artifacts.require("TaxReport");

contract('TaxFramework', function(accounts) {
    const testSetEmployee = async function (type, acctID, stringTag) {
        let instance = await EmploymentRecord.deployed();
        await instance.setEmployee(type,acctID,"Bob Marley");
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


    it("Pre-6a should create Tax Entities for all mapped employees", async function() {
    let instance = await TaxAgency.deployed();
    let countBefore = await instance.indexCount.call();
    instance.setTaxEntity(accounts[0],true,true,0,"Bob Marley");
    instance.setTaxEntity(accounts[1],true,true,0,"Bob Marley");
    instance.setTaxEntity(accounts[2],true,true,0,"Bob Marley");
    instance.setTaxEntity(accounts[3],true,true,0,"Bob Marley");
    let countAfter = await instance.indexCount.call();
    assert.equal(countAfter.valueOf(), countBefore.toNumber() + 4, "Four tax entities were not set");
    });

    let instanceTAgencyId = await (TaxAgency.deployed()).address;//instanceTAgency.address
    const spawnTaxReport = function(instance,taxEntityId,taxAgencyId) {
      let reportAddress = await (TaxReport.new({from: taxEntityId}, taxAgencyId,2017)).address;
      // Check for existent contract
      // Check for contract in TaxAgency
    }
    it("Pre-6b should create Tax Report for all mapped employees", async function() {
      let instance = await TaxAgency.deployed();
      await spawnTaxReport(instance,accounts[0],instanceTAgencyId);
      await spawnTaxReport(instance,accounts[1],instanceTAgencyId);
      await spawnTaxReport(instance,accounts[2],instanceTAgencyId);
      await spawnTaxReport(instance,accounts[3],instanceTAgencyId);
    });

    // Consider making frequency just input for seconds
    var pay_init = 250000;
    var freq_init = 4;
    var endTime_init = 31556926;
    var taxType_init = 0;
    var withHold_init = 0;

    it("6 should create and map a Payment for existing employee", async function() {
      let instance = await EmploymentRecord.deployed();
      let instanceTax = await TaxAgency.deployed();
      var taxReportAddr = instanceTax.taxReports.call(accounts[1]);
  
      var countBefore = await instance.getPaymentContractsCount.call();
      await instance.setPayment(accounts[1], 0, 0, pay_init, freq_init, endTime_init);
      var countAfter = await instance.getPaymentContractsCount.call();
      assert.equal(countAfter.valueOf(), (++countBefore).valueOf(), "Payment not successfully created and mapped");
    });

    // Requires timemachine, accounts that are not accounts[0]
    // Attempt to timely ask for a withdraw on a Payment from employee
    it("9 should pay employee from Payment", async function() {
        let instance = await EmploymentRecord.deployed();

        let paymentAddress = await instance.paymentContracts.call(accounts[1]);
        let paymentInstance = Payment.at(paymentAddress);

        let pay = await paymentInstance.payPer.call();
        let freq = await paymentInstance.freq.call();
        console.log(freq.valueOf());

        // Timemachine call
        //await increaseTime(freq.valueOf());
        console.log(freq.valueOf());

        let balanceOwnerBefore = await web3.eth.getBalance(paymentAddress);
        await paymentInstance.payout( {from: accounts[0], value: pay.valueOf()} );
        let balanceOwnerAfter = await web3.eth.getBalance(paymentAddress);
        assert.notEqual(balanceOwnerAfter.valueOf(), balanceOwnerBefore.valueOf(), "Owner payout was not successful");

        // Reverting to correct block
        //await increaseTime(-freq.valueOf());

        let balanceBefore = await web3.eth.getBalance(accounts[1]);
        await paymentInstance.withdraw( {from: accounts[1]} );
        let balanceAfter = await web3.eth.getBalance(accounts[1]);
        assert.notEqual(balanceBefore.valueOf(), balanceAfter.valueOf(), "Payment was not successful");
    }); // TODO: TIMEMACHINE IS COMMENTED OUT
    it("10 should display logs of taxable transactions from tax reports", async function() {
        let instance = await TaxAgency.deployed();
        let taxReportAddr = await (instance.taxReports.call(0)).call(0);
        var taxReport = TaxReport.at(taxReportAddr);
        let filedTaxItemEvent = taxReport.FiledTaxItemEvent({}, {fromBlock: 0, toBlock: 'latest'});
        filedTaxItemEvent.get((error,logs) => {
          logs.forEach(log => console.log(log.args));
        });
        // https://ethereum.stackexchange.com/questions/16313/how-can-i-view-event-logs-for-an-ethereum-contract?rq=1
      });
});