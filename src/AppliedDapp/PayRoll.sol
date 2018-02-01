pragma solidity ^0.4.11;

/*
https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
https://vomtom.at/solidity-send-vs-transfer/
https://zupzup.org/smart-contract-interaction/
https://github.com/PeterBorah/smart-contract-security-examples/issues/3
http://vessenes.com/more-ethereum-attacks-race-to-empty-is-the-real-deal/
*/

contract Owned {
    address owner;
    bool active;

    function Owned( ) public {
        owner = msg.sender;
        active = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function getActive( ) public constant returns(bool) {return active;}

    function stop( ) public onlyOwner {
        active = false;
    }

    function close( ) public onlyOwner {
        selfdestruct(owner);
    }
}


// CHECK THE SECURITY RISKS FIRST!! PROBABLY THE REASON FOR THE DAO HACK
contract Mutex {
    bool locked;
    modifier noReentrancy( ) {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}


// Enums in Solidity: https://ethereum.stackexchange.com/questions/24086/how-do-enums-work/24087
contract EmploymentRecord is Owned {

    event EmployeeCreation( );
    event AccessEmployeeEvent(
        string fName,
        string lName,
        EmploymentType status,
        bool active
    );

    enum EmploymentType {OWNER, PERM, CASUAL, CONTRACT}

    struct Employee {
        string fName;
        string lName;
        EmploymentType status;
        bool active;
    }

    mapping (address => Employee) public employees;
    address[] public employeeAccts;

    // maps employee address to contract address
    mapping (address => address) public paymentContracts;
    // index of created payment contracts
    address[] public paymentIndex;

    function setEmployee(address _addr, string _fName, string _lName, EmploymentType _status) public onlyOwner {
        require(employees[_addr].active == false);

        Employee memory e = Employee(_fName, _lName, _status, true);
        employees[_addr] = e;

        employeeAccts.push(_addr);

        EmployeeCreation();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) public {
        Employee memory e = employees[_addr];
        AccessEmployeeEvent(e.fName,e.lName,e.status,e.active);
    }

    // https://ethereum.stackexchange.com/questions/27777/deploying-contract-factory-structure-in-remix
    // https://blog.aragon.one/advanced-solidity-code-deployment-techniques-dc032665f434
    function getPaymentContractCount( ) public constant returns(uint _length) {
        return paymentIndex.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    // https://ethereumdev.io/manage-several-contracts-with-factories/
    function createPayment(EmploymentType _status, address _employee, uint _pay, uint _frequency, uint _end) public onlyOwner returns(address _newPayment) {
        Payment p = Payment(paymentContracts[_employee]);

        // Check if there already exists a Payment contract, that is still active
        require(!p.getActive());
        // Notes on require: https://medium.com/blockchannel/the-use-of-revert-assert-and-require-in-solidity-and-the-new-revert-opcode-in-the-evm-1a3a7990e06e

        // address, payPerFrequency, frequency, endTime
        // OWNER, PERM, CASUAL, CONTRACT
        if (_status == EmploymentRecord.EmploymentType.PERM) {
            PermanentPay _perm = new PermanentPay(_employee,_pay,_frequency);
            paymentContracts[_employee] = _perm;
            paymentIndex.push(_perm);
            return _perm;
        } else if (_status == EmploymentRecord.EmploymentType.CASUAL) {
            CasualPay _casual = new CasualPay(_employee,_pay);
            paymentContracts[_employee] = _casual;
            paymentIndex.push(_casual);
            return _casual;
        } else if (_status == EmploymentRecord.EmploymentType.CONTRACT) {
            ContractPay _contract = new ContractPay(_employee,_pay,_frequency,_end);
            paymentContracts[_employee] = _contract;
            paymentIndex.push(_contract);
            return _contract;
        } else {
            revert();
        }
    }
}


contract Payment is Owned {
    event PaymentCreationEvent (
      address owner,
      address receiver,
      uint payInDollars
    );

    // https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
    event PaymentEvent (
      address owner,
      address receiver,
      uint payInDollars,
      uint datePaid // LOOK INTO FURTHER (timestamp, now)
    );

    // NONE, WEEKLY, BI_WEEKLY, SEMI_MONTHLY, MONTHLY
    // Note: Not supported to be constant as of yet
    uint[] public frequencies = [0,604800,302400,1314871,2629743];

    // Contract members
    address receiver;
    // Representative of onetime/wage/salary pay per frequency timespan
    uint pay;
    uint frequency;
    uint endTime;

    uint lastUpdate;
    bool payCondition;

    // address, payPerFrequency, frequency, endTime

    function Payment(address _receiver, uint _pay, uint _frequency, uint _endTime) public {
      receiver = _receiver;
      pay = _pay;
      frequency = frequencies[_frequency];
      endTime = _endTime;
      lastUpdate = now;

      PaymentCreationEvent(owner,_receiver,_pay);
    }

    function setPayCondition( ) public;

    function payout( ) public payable onlyOwner {
        require(!payCondition);

        // Notes on ether transfer: https://vomtom.at/solidity-send-vs-transfer/
        // take from owner
        // send to owner

        PaymentEvent(owner,receiver,pay,now);
    }
}


contract PermanentPay is Payment {
    // http://solidity.readthedocs.io/en/develop/contracts.html#arguments-for-base-constructors
    function PermanentPay(address _receiver, uint _pay, uint _frequency) public Payment(_receiver, _pay, _frequency, 0) { }

    function setPayCondition( ) public {
        payCondition = true;
    }
}


contract CasualPay is Payment {
    function CasualPay(address _receiver, uint _pay) public Payment(_receiver,_pay,0,0) { }

    function setPayCondition( ) public onlyOwner {
      payCondition = true;
    }
}


contract ContractPay is Payment {
    uint payFrequency;
    uint contractEndTime;

    function ContractPay(address _receiver, uint _pay, uint _payFrequency, uint _endTime) public Payment(_receiver,_pay,_payFrequency,_endTime) { }

    function setPayCondition( ) public {
        payCondition = true;
    }

    function earlyTermination( ) public onlyOwner {
      stop();
    }
}

