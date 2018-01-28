pragma solidity ^0.4.11;

contract owned {
    address owner;
    bool stopped;

    function owned() public { owner = msg.sender; }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
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

    function setEmployee(address _addr, string _fName, string _lName, EmploymentType _status) public onlyOwner{
        require(employees[_addr].active == false);

        Employee memory e = Employee(_fName, _lName, _status, true);
        employees[_addr] = e;

        employeeAccts.push(_addr);

        EmployeeCreation();
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

    uint constant MONTHLY = 2629743;
    uint constant WEEKLY = 604800;
    uint constant SEMI_MONTHLY = 1314871;
    uint constant BI_WEEKLY = 302400;

    // Contract members
    address receiver;
    // Representative of onetime/wage/salary pay
    uint payInDollars;
    uint lastUpdate;
    bool payCondition = false;

    function Payment(address _receiver, uint _pay) public {
      receiver = _receiver;
      payInDollars = _pay;
      lastUpdate = now;

      PaymentCreationEvent(owner,_receiver,_pay);
    }

    function setPayCondition() public;

    function payout() public onlyOwner {
        if (!payCondition) revert(); // Return gas
        // take from owner
        // send to owner

        PaymentEvent(owner,receiver,payInDollars,now);
    }

}


contract PermanentPay is Payment {
    uint payFrequency;

    // http://solidity.readthedocs.io/en/develop/contracts.html#arguments-for-base-constructors
    function PermanentPay(address _receiver, uint _pay, uint _payFrequency) public Payment(_receiver,_pay) {
      payFrequency = _payFrequency;
    }

    function setPayCondition() public {
        payCondition = true;
    }
}

contract CasualPay is Payment {
    function CasualPay(address _receiver, uint _pay) public Payment(_receiver,_pay) {}

    function setPayCondition() public onlyOwner {
      payCondition = true;
    }
}

contract ContractPay is Payment {
    uint payFrequency;
    uint contractEndTime;

    function ContractPay(address _receiver, uint _pay, uint _payFrequency, uint _endTime) public Payment(_receiver,_pay) {
      contractEndTime = _endTime;
      payFrequency = _payFrequency;
    }

    function setPayCondition() public {
        payCondition = true;
    }

    function earlyTermination() public onlyOwner {
      close();
    }
}

// https://ethereum.stackexchange.com/questions/27777/deploying-contract-factory-structure-in-remix
// https://blog.aragon.one/advanced-solidity-code-deployment-techniques-dc032665f434
contract PaymentFactory is owned {
    enum EmploymentType {PERM, CASUAL, CONTRACT}

    // index of created payment contracts
    address[] public paymentContracts;

    function getPaymentContractCount() public constant returns(uint _length) {
        return paymentContracts.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    // https://ethereumdev.io/manage-several-contracts-with-factories/
    function createPayment(EmploymentType _status) public onlyOwner returns(address _newPayment) {
        if (_status == PaymentFactory.EmploymentType.PERM) {
            PermanentPay _perm = new PermanentPay(_employee,100,100);
            paymentContracts.push(_perm);
            return _perm;
        } else if (_status == PaymentFactory.EmploymentType.PERM) {
            CasualPay _casual = new CasualPay(_employee,100);
            paymentContracts.push(_casual);
            return _casual;
        } else if (_status == PaymentFactory.EmploymentType.PERM) {
            ContractPay _contract = new ContractPay(_employee,100,100,100);
            paymentContracts.push(_contract);
            return _contract;
        } else {
            revert();
        }
    }
}

