pragma solidity ^0.4.11;

contract owned {
    address owner;
    bool active;

    function owned() public {
        owner = msg.sender;
        active = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function getActive() public constant returns(bool) {return active;}

    function stop() public onlyOwner {
        active = false;
    }

    function close() public onlyOwner {
        selfdestruct(owner);
    }
}


// CHECK THE SECURITY RISKS FIRST!! PROBABLY THE REASON FOR THE DAO HACK
contract Mutex {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}


// Enums in Solidity: https://ethereum.stackexchange.com/questions/24086/how-do-enums-work/24087
contract EmploymentRecord is owned {

    event EmployeeCreation();

    enum EmploymentType {PERM, CASUAL, CONTRACT}

    struct Employee {
        string fName;
        string lastName;
        EmploymentType status;
        bool active;
    }

    mapping (address => Employee) public employees;
    address[] public employeeAccts;

    // maps employee address to contract address
    mapping (address => address) public paymentContracts;
    // index of created payment contracts
    address[] public paymentIndex;

    function setEmployee(address _addr, string _fName, string _lName, EmploymentType _status) public onlyOwner{
        require(employees[_addr].active == false);

        Employee memory e = Employee(_fName, _lName, _status, true);
        employees[_addr] = e;

        employeeAccts.push(_addr);

        EmployeeCreation();
    }

    // https://ethereum.stackexchange.com/questions/27777/deploying-contract-factory-structure-in-remix
    // https://blog.aragon.one/advanced-solidity-code-deployment-techniques-dc032665f434
    function getPaymentContractCount() public constant returns(uint _length) {
        return paymentIndex.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    // https://ethereumdev.io/manage-several-contracts-with-factories/
    function createPayment(address _employee, EmploymentType _status) public onlyOwner returns(address _newPayment) {
        // Check if there already exists a Payment contract, that is still active
        // Notes on require: https://medium.com/blockchannel/the-use-of-revert-assert-and-require-in-solidity-and-the-new-revert-opcode-in-the-evm-1a3a7990e06e
        Payment p = Payment(paymentContracts[_employee]);
        require(!p.getActive());

        // address, payPerFrequency, frequency, endTime
        if (_status == EmploymentRecord.EmploymentType.PERM) {
            PermanentPay _perm = new PermanentPay(_employee,100,100);
            paymentContracts[_employee] = _perm;
            paymentIndex.push(_perm);
            return _perm;
        } else if (_status == EmploymentRecord.EmploymentType.PERM) {
            CasualPay _casual = new CasualPay(_employee,100);
            paymentContracts[_employee] = _casual;
            paymentIndex.push(_casual);
            return _casual;
        } else if (_status == EmploymentRecord.EmploymentType.PERM) {
            ContractPay _contract = new ContractPay(_employee,100,100,100);
            paymentContracts[_employee] = _contract;
            paymentIndex.push(_contract);
            return _contract;
        } else {
            revert();
        }
    }
}


contract Payment is owned {
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
    uint [] public frequencies = [0,604800,302400,1314871,2629743];

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

    function setPayCondition() public;

    function payout() public onlyOwner {
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

    function setPayCondition() public {
        payCondition = true;
    }
}


contract CasualPay is Payment {
    function CasualPay(address _receiver, uint _pay) public Payment(_receiver,_pay,0,0) { }

    function setPayCondition() public onlyOwner {
      payCondition = true;
    }
}


contract ContractPay is Payment {
    uint payFrequency;
    uint contractEndTime;

    function ContractPay(address _receiver, uint _pay, uint _payFrequency, uint _endTime) public Payment(_receiver,_pay,_payFrequency,_endTime) { }

    function setPayCondition() public {
        payCondition = true;
    }

    function earlyTermination() public onlyOwner {
      stop();
    }
}

