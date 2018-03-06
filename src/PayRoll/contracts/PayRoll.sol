pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";

contract EmploymentRecord is Owned, Mutex {
    enum EmploymentType {OWNER, PERM, CASUAL, CONTRACT}
    event EmployeeCreationEvent( );
    event CheckPaymentEvent(address paymentContract);
    event AccessEmployeeEvent(
        bool active,
        EmploymentType status,
        bytes16 fName,
        bytes16 lName
    );
    struct Employee {
        bool active;
        EmploymentType status;
        bytes16 fName;
        bytes16 lName;
    }

    // maps employee address to a employee struct
    mapping (address => Employee) public employees;
    address[] public employeeIndex;

    // maps employee address to contract address
    mapping (address => address) public paymentContracts;
    address[] public paymentIndex;

    function setEmployee(
        EmploymentType _status,
        address _addr,
        bytes16 _fName,
        bytes16 _lName
    )
        public
        onlyOwner
    {
        require(employees[_addr].active == false);

        // Creating new Employee and recording the address
        Employee memory e = Employee(true,_status, _fName, _lName);
        employees[_addr] = e;
        employeeIndex.push(_addr);

        //EmployeeCreationEvent();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) external noReentrancy returns(bool) {
        Employee memory e = employees[_addr];
        AccessEmployeeEvent(e.active,e.status,e.fName,e.lName);
        return e.active;
    }

    // Consider making payable for during creation
    function createPayment(
        address _employee
        //uint256 _pay,
        //uint256 _freq,
        //uint256 _end
    )
        public
        onlyOwner
    {
        require(paymentIndex.length < 100);
        require(employees[_employee].active);
 /*
        PermanentPay p = PermanentPay(paymentContracts[_employee]);
        require(!p.active());
 */
 //       var _status = employees[_employee].status;
        
        uint256 _pay = 250000;
        uint256 _freq = 1;
        PermanentPay _perm = new PermanentPay(owner,_employee,_pay,_freq);
        paymentContracts[_employee] = _perm;
        paymentIndex.push(_perm);

        //CheckPaymentEvent(paymentContracts[_employee]);
       /*
        // Creating different payment contracts based off the employment types
        if (_status == EmploymentRecord.EmploymentType.PERM || _status == EmploymentRecord.EmploymentType.OWNER) {
            PermanentPay _perm = new PermanentPay(_employer,_employee,_pay,_freq);
            paymentContracts[_employee] = _perm;
            paymentIndex.push(_perm);
            return _perm;
        } else if (_status == EmploymentRecord.EmploymentType.CASUAL) {
            CasualPay _casual = new CasualPay(_employer,_employee,_pay);
            paymentContracts[_employee] = _casual;
            paymentIndex.push(_casual);
            return _casual;
        } else if (_status == EmploymentRecord.EmploymentType.CONTRACT) {
            ContractPay _contract = new ContractPay(_employer,_employee,_pay,_freq,_end);
            paymentContracts[_employee] = _contract;
            paymentIndex.push(_contract);
            return _contract;
        } else {
            revert();
        } */
        //CheckPaymentEvent(paymentContracts[_employee]);
    }

    function checkPayment() external noReentrancy {
        // Ensuring that only the exact employee can access and that the employee is active
        require(employees[msg.sender].active);
        CheckPaymentEvent(paymentContracts[msg.sender]);
    }

    function ownerCheckPayment(address _employee) external onlyOwner {
        // Ensuring the only the employee is active
        require(employees[_employee].active);
        CheckPaymentEvent(paymentContracts[_employee]);
    }


    function updateEmployeeActiveFlag(address _employee, bool _active) public onlyOwner {
        employees[_employee].active = _active;
    }

    function updateEmployeeStatus(address _employee, EmploymentType _status) public onlyOwner {
        employees[_employee].status = _status;
    }

    function getEmployeeCount( ) public constant returns(uint256 _length) {
        return employeeIndex.length;
    }

    function getPaymentContractsCount( ) public constant returns(uint256 _length) {
        return paymentIndex.length;
    }
}


contract Payment is Owned {
    event PaymentCreationEvent( );
    event PaymentEvent (
        bytes8 msg,
        uint256 pay,
        uint256 datePaid,
        uint256 bal
    );

    address employer; address employee;
    uint256 lastUpdate; uint256 public payPer; uint256 public freq; uint256 endTime; uint256 owed;
    uint256[] private FREQUENCIES = [0, 0.5 weeks, 1 weeks, 2 weeks, 4 weeks];

    // Considering making it payable
    function Payment(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _endTime
    )
        public
    {
        employer = _employer;
        employee = _employee;
        payPer = _pay;
        freq = FREQUENCIES[_freq]; // Possible error with invalid Frequencies
        endTime = now + _endTime;
        lastUpdate = now;
        owed = 0;
        PaymentCreationEvent();
    }

    // Functions only when payout was previously called
    function withdraw( ) external payable {
        // Withdrawal Authorization, Employee
        require(msg.sender == employee);
        require(owed > 0);

        // Money Transfer
        if (owed > this.balance) {
            PaymentEvent("Pending",owed,now,this.balance);
        } else {
            uint balanceBefore = this.balance;
            employee.transfer(owed);
            assert(this.balance == balanceBefore-owed);

            PaymentEvent("Success",owed,now,this.balance);
        }
    }

    // Is required to refill a Payment contract for the Employee to withdraw
    function payout( ) external payable {
        // Payout Authorization, Employer
        require(msg.sender == employer);
        setPay();
        require(owed > 0);

        // Ensuring that Payment is capable of paying
        if (owed > this.balance) {
            PaymentEvent("Pending",owed,now,this.balance);
        } else {
            PaymentEvent("Applied",owed,now,this.balance);
        }
    }

    function setPay( ) internal;
}


contract PermanentPay is Payment {
    function PermanentPay(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq
    )
        Payment(_employer,_employee, _pay, _freq, 0)
        public
    { }

    // Based off of freq
    function setPay( ) internal {
        uint256 freqCount = (now-lastUpdate)%freq;
        lastUpdate = now;
        owed += freqCount*payPer;
    }
}
contract CasualPay is Payment {
    function CasualPay(
        address _employer,
        address _employee,
        uint256 _pay
    )
        Payment(_employer,_employee,_pay,0,0)
        public
     { }

    function setPay( ) internal {
        lastUpdate = now;
        owed += payPer;
    }
}
contract ContractPay is Payment {
    function ContractPay(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _endTime
    )
        Payment(_employer,_employee,_pay,_freq,_endTime)
        public 
     { }

    // Based off of freq and contract endTime
    function setPay( ) internal {
        uint256 benchmark = (endTime - now >= 0) ? now : endTime;
        uint256 freqCount = (benchmark-lastUpdate)%freq;
        lastUpdate = now;
        owed += freqCount*payPer;
    }
}

