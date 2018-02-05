pragma solidity ^0.4.11;

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

    function getActive( ) public constant returns(bool) { return active; }

    function stop( ) public onlyOwner { active = false; }

    function close( ) public onlyOwner { selfdestruct(owner); }
}


// Used to prevent callback attacks
contract Mutex {
    bool locked;
    modifier noReentrancy( ) {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}


contract EmploymentRecord is Owned, Mutex {

    event EmployeeCreation( );
    event CheckPayment(address paymentContract);
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

    // maps employee address to a employee struct
    mapping (address => Employee) public employees;
    address[] public employeeAccts;

    // maps employee address to contract address
    mapping (address => address) public paymentContracts;
    // index of created payment contracts
    address[] public paymentIndex;

    function setEmployee(
    	address _addr,
    	string _fName,
    	string _lName,
    	EmploymentType _status
    )
    	public
    	onlyOwner
    {
        require(employees[_addr].active == false);

        Employee memory e = Employee(_fName, _lName, _status, true);
        employees[_addr] = e;

        employeeAccts.push(_addr);

        EmployeeCreation();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) public noReentrancy {
        Employee memory e = employees[_addr];
        AccessEmployeeEvent(e.fName,e.lName,e.status,e.active);
    }

    function createPayment(
    	EmploymentType _status,
    	address _sender,
    	address _employee,
    	uint _pay,
    	uint _frequency,
    	uint _end
    )
    	public
    	onlyOwner
    	returns(address _newPayment)
    {
        // Ensuring that gasSize is not overflowed when going over every individual payouts
        if (paymentIndex.length > 100) {revert();}
        // Ensuring that Payments are only given to actual Employees
        if (!employees[_employee].active) {revert();}

        // Check if there already exists a Payment contract, that is still active
        Payment p = Payment(paymentContracts[_employee]);
        require(!p.getActive());

        // Creating different payment contracts based off the employment types
        if (_status == EmploymentRecord.EmploymentType.PERM || _status == EmploymentRecord.EmploymentType.OWNER) {
            PermanentPay _perm = new PermanentPay(_sender,_employee,_pay,_frequency);
            paymentContracts[_employee] = _perm;
            paymentIndex.push(_perm);
            return _perm;
        } else if (_status == EmploymentRecord.EmploymentType.CASUAL) {
            CasualPay _casual = new CasualPay(_sender,_employee,_pay);
            paymentContracts[_employee] = _casual;
            paymentIndex.push(_casual);
            return _casual;
        } else if (_status == EmploymentRecord.EmploymentType.CONTRACT) {
            ContractPay _contract = new ContractPay(_sender,_employee,_pay,_frequency,_end);
            paymentContracts[_employee] = _contract;
            paymentIndex.push(_contract);
            return _contract;
        } else {
            revert();
        }
    }

    function checkPayment() public noReentrancy {
    	// Ensuring that only the exact employee can access and that the employee is active
    	require(employees[msg.sender].active);
    	CheckPayment(paymentContracts[msg.sender]);
    }

    function ownerCheckPayment(address _employee) public onlyOwner {
    	// Ensuring the only the employee is active
    	require(employees[_employee].active);
    	CheckPayment(paymentContracts[_employee]);
    }

    function getPaymentContractCount( ) public constant returns(uint _length) {
        return paymentIndex.length;
    }
}


contract Payment is Owned {
    event PaymentCreationEvent (
      address sender,
      address receiver,
      uint payInDollars
    );

    event PaymentEvent (
      address sender,
      address receiver,
      uint payInDollars,
      uint datePaid
    );

    // NONE, WEEKLY, BI_WEEKLY, SEMI_MONTHLY, MONTHLY
    uint[] public FREQUENCIES = [0,604800,302400,1314871,2629743];

    // Contract members
    address sender; address receiver;
    // Representative of onetime/wage/salary pay per frequency timespan
    uint pay;
    uint frequency; uint endTime; uint payCounter;

    // Used for the actual payout
    uint lastUpdate;
    bool payCondition;

    function Payment(
    	address _sender,
    	address _receiver,
    	uint _pay,
    	uint _frequency,
    	uint _endTime
    )
    	public
    {
      sender = _sender;
      receiver = _receiver;
      pay = _pay;
      frequency = FREQUENCIES[_frequency];
      endTime = _endTime;
      lastUpdate = now;

      PaymentCreationEvent(owner,_receiver,_pay);
    }

    // Need to take from owner: Done previously either at construction or after successful payment
    function withdraw( ) public payable {
    	// Withdrawal Authorization, Employee
    	require(msg.sender == receiver);
        setPayCondition();
        require(payCondition);

        // Money Transfer
        receiver.transfer(pay);
        payCounter++;
        payCondition = false;

        PaymentEvent(owner,receiver,pay,now);
    }

    function payout( ) public payable {
    	// Payout Authorization, Employer
    	require(msg.sender == sender);
        setPayCondition();
        require(payCondition);

        // Money Transfer
        receiver.transfer(pay);
        payCounter++;
        payCondition = false;

        PaymentEvent(owner,receiver,pay,now);
    }

    function setPayCondition( ) private returns(uint);
}


contract PermanentPay is Payment {
    function PermanentPay(
    	address _sender,
    	address _receiver,
    	uint _pay,
    	uint _frequency
    )
    	Payment(_sender,_receiver, _pay, _frequency, 0)
    	public
    { }

    // Based off of frequency
    function setPayCondition( ) private returns(uint) {
        if (frequency <= lastUpdate - now) {
            payCondition = true;
        }
    }
}

contract CasualPay is Payment {
    function CasualPay(
    	address _sender,
    	address _receiver,
    	uint _pay
    )
    	Payment(_sender,_receiver,_pay,0,0)
    	public
 	{ }

    function setPayCondition( ) private returns(uint) {
      payCondition = true;
      return 1;
    }
}


contract ContractPay is Payment {
    function ContractPay(
    	address _sender,
    	address _receiver,
    	uint _pay,
    	uint _frequency,
    	uint _endTime
    )
		Payment(_sender,_receiver,_pay,_frequency,_endTime)
    	public 
 	{ }

    // Based off of frequency and contract endTime
    function setPayCondition( ) private returns(uint) {
        if (frequency <= lastUpdate - now && now < endTime) {
            payCondition = true;
        }
    }
}

