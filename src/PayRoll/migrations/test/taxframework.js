import 'babel-polyfill';
//import './app';

// Used for testing in application context
var EmploymentRecord = artifacts.require("EmploymentRecord");
var Payment = artifacts.require("Payment");
var TaxAgency = artifacts.require("TaxAgency");
var TaxReport = artifacts.require("TaxReport");

contract('TaxFramework', function(accounts) {
    // https://ethereum.stackexchange.com/questions/15670/deploying-a-contract-at-test-time-with-truffle
    var myCode = '';
    var Payroll2 = EmploymentRecord.new({data: myCode, gas: 4700000, from: accounts[1]});
    console.log(Payroll2.address);
    var Agency1 = TaxAgency.new({from: accounts[5]});
    var Agency2 = TaxAgency.new({from: accounts[5]});

    const testSetEmployee = async function (type, acctID, stringTag) {
        let instance = await EmploymentRecord.deployed();
        await instance.setEmployee(type,acctID,"Bob Marley");
        let activeStatus = await instance.accessEmployee.call(acctID);
        assert.equal(activeStatus, true, "Did not create employee, nor properly mapped for: " + stringTag);
    }
    it("1 should create and map employee1 to Payroll1", async function() {
        testSetEmployee(1, accounts[2], "Employee1");
    });
    it("2 should create and map permanent employee2 to Payroll1", async function() {
        testSetEmployee(1, accounts[3], "Employee2");
    });
    it("3 should create and map employee3 to Payroll2", async function() {
        /*
        await Payroll2.setEmployee(1,accounts[4],"Bob Marley");
        let activeStatus = await Payroll2.accessEmployee.call(accounts[4]);
        assert.equal(activeStatus, true, "Did not create employee, nor properly mapped for: Employee3");
        */
       //var count = Payroll2.getEmployeeCount.call();
       //console.log(count);
    });

/*
    const setTaxEntity = async function (instance, textResponse ) {
        let countBefore = await instance.indexCount.call();
        for (i = 0; i < 5; i++)
        {
            instance.setTaxEntity(accounts[i],true,true,0,"Bob Marley");
        }
        let countAfter = await instance.indexCount.call();
        assert.equal(countAfter.valueOf(), countBefore.toNumber() + 5, taxResponse + "Five tax entities were not set");
    }
    it("Pre-4a should create Tax Entities for all mapped employees", async function() {
        setTaxEntity(Agency1, "Agency 1: ");
        setTaxEntity(Agency2, "Agency 2: ");
    });

    it("Pre-4b should create Tax Report for all mapped employees", async function() {
        for (i = 0; i < 5; i++) {
            await Agency1.spawnTaxReport({from: accounts[i]})
            await Agency2.spawnTaxReport({from: accounts[i]})
        }

    });

    // Consider making frequency just input for seconds
    var pay_init = 250000;
    var withHold_init = 0;

    it("4 should create and map a Payment for existing employee", async function() {
        let instance = await EmploymentRecord.deployed();
        let instanceTax = await TaxAgency.deployed();
        var taxReportAddr = instanceTax.taxReports.call(accounts[1]);

        var countBefore = await instance.getPaymentContractsCount.call();
        await instance.setPayment(accounts[1], 0, 0, pay_init);
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

        // Timemachine call
        //await increaseTime(freq.valueOf());

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
        //let instance = await TaxAgency.deployed();
        //let taxReportAddr = await (instance.taxReports.call(0)).call(0);
        let taxReportAddr = await (Agency1.taxReports.call(0)).call(0);
        var taxReport = TaxReport.at(taxReportAddr);
        let filedTaxItemEvent = taxReport.FiledTaxItemEvent({}, {fromBlock: 0, toBlock: 'latest'});
        filedTaxItemEvent.get((error,logs) => {
          logs.forEach(log => console.log(log.args));
        });
        // https://ethereum.stackexchange.com/questions/16313/how-can-i-view-event-logs-for-an-ethereum-contract?rq=1
    });
    */
});