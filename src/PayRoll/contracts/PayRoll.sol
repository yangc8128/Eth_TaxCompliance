pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
import "./Payment.sol";
import "./TaxAgencies.sol";
import { EmployeeMap } from "./PayrollLib.sol";
import { PaymentContractMap } from "./PayrollLib.sol";

// Contract can be split into libraries
contract EmploymentRecord is Owned, Mutex {
    enum EmploymentType {OWNER, PERM, CASUAL, CONTRACT}
    event EmployeeCreationEvent( );
    event CheckPaymentEvent(address paymentContract);
    event AccessEmployeeEvent(
        bool active,
        EmploymentType status,
        bytes32 name
    );

    EmployeeMap.Data private _employeeMap;
    PaymentContractMap.Data private _paymentMap;

    function setEmployee(
        EmploymentType _status,
        address _addr,
        bytes32 _name
    )
        public
        onlyOwner
    {
        require(_employeeMap.getMap(_addr).active == false);

        _employeeMap.insert(_status,_name,_addr);
        EmployeeCreationEvent();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) external noReentrancy returns(bool) {
        EmployeeMap.Employee memory e = _employeeMap.getMap(_addr);
        AccessEmployeeEvent(e.active,e.status,e.name);
        return e.active;
    }

    function setPayment(
        address _employee,
        address _addrReturn,
        uint64 _withHold,
        uint256 _pay
    )
        public
        onlyOwner
    {
        createPayment(_employee,_pay);
        setTaxes(_employee,_addrReturn,_withHold);
    }

    // Consider making payable for during creation
    function createPayment(
        address _employee,
        uint256 _pay
    )
        internal
    {
        _paymentMap.requireSmall(100);
        _employeeMap.requireActive(_employee);

        uint size;
        address payAddr = _paymentMap.getMap(_employee);
        assembly { size := extcodesize(payAddr) }
        Payment p = Payment(payAddr);
        require(size == 0 || !(p.active()));

        Payment _payment = new Payment(owner,_employee,_pay);
        _paymentMap.insert(_payment);

        CheckPaymentEvent(_paymentMap.getMap(_employee));
    }

    function setTaxes(
        address _employee,
        address _addrReturn,
        uint64 _withHold
    )
        internal
    {
        require(employees[_employee].active);
        address _payAddr = paymentContracts[_employee];
        uint size;
        assembly { size := extcodesize(_payAddr) }
        Payment p = Payment(_payAddr);
        require(size != 0 || p.active());

        p.setTaxable(_addrReturn, _withHold);
    }

    function checkPayment() external noReentrancy {
        // Ensuring that only the exact employee can access and that the employee is active
        _employeeMap.requireActive(msg.sender);
        CheckPaymentEvent(_paymentMap.getMap(msg.sender));
    }

    function ownerCheckPayment(address _employee) external onlyOwner {
        // Ensuring the only the employee is active
        _employeeMap.requireActive(_employee);
        CheckPaymentEvent(_paymentMap.getMap(_employee));
    }
}
