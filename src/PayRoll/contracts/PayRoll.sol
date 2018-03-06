pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
import { EmployeeMap } from "./PayRollLib.sol";
import { PaymentContractMap } from "./PayRollLib.sol";

contract EmploymentRecord is Owned, Mutex {
    event EmployeeCreationEvent( );
    event CheckPaymentEvent(address paymentContract);
    event AccessEmployeeEvent(
        bool active,
        EmployeeMap.EmploymentType status,
        bytes16 fName,
        bytes16 lName
    );

    EmployeeMap.Data private _employeeMap;
    PaymentContractMap.Data private _paymentContractMap;

    function setEmployee(
        uint _status,
        bytes16 _fName,
        bytes16 _lName,
        address _addr
    )
        public
        onlyOwner
    {
        _employeeMap.insert(_status,_fName,_lName,_addr);
        EmployeeCreationEvent();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) external noReentrancy returns(bool) {
        EmployeeMap.Employee memory e = _employeeMap.getMap(_addr);
        AccessEmployeeEvent(e.active,e.status,e.fName,e.lName);
        return e.active;
    }

    // Consider making payable for during creation
    function createPayment(
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _end
    )
        public
        onlyOwner
    {
        _paymentContractMap.requireSmallPayInded(100);
        _employeeMap.requireActiveEmpl(_employee);
   /*
        Payment p = Permanent(paymentContracts[_employee]);
        require(!p.active());
   */
        var _status = _employeeMap.getMap(_employee).status;

        // Creating different payment contracts based off the employment types
        if (_status == EmploymentRecord.EmploymentType.PERM || _status == EmploymentRecord.EmploymentType.OWNER) {
            PermanentPay _perm = new PermanentPay(owner,_employee,_pay,_freq);
            _paymentContractMap.insert(_perm);
        } else if (_status == EmploymentRecord.EmploymentType.CASUAL) {
            CasualPay _casual = new CasualPay(owner,_employee,_pay);
            _paymentContractMap.insert(_casual);
        } else if (_status == EmploymentRecord.EmploymentType.CONTRACT) {
            ContractPay _contract = new ContractPay(owner,_employee,_pay,_freq,_end);
            _paymentContractMap.insert(_contract);
        } else {
            revert();
        } 
        CheckPaymentEvent(_paymentContractMap.getMap(_employee));
    }

    function checkPayment() external noReentrancy {
        // Ensuring that only the exact employee can access and that the employee is active
        _employeeMap.requireActiveEmpl(msg.sender);
        CheckPaymentEvent(_paymentContractMap.getMap(msg.sender));
    }

    function ownerCheckPayment(address _employee) external onlyOwner {
        // Ensuring the only the employee is active
        _employeeMap.requireActiveEmpl(_employee);
        CheckPaymentEvent(_paymentContractMap.getMap(_employee));
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

