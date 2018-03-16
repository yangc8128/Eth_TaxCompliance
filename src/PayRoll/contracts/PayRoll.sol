pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
import "./Payment.sol";
import "./TaxAgencies.sol";

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
    struct Employee {
        bool active;
        EmploymentType status;
        bytes32 name;
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
        bytes32 _name
    )
        public
        onlyOwner
    {
        require(employees[_addr].active == false);

        // Creating new Employee and recording the address
        Employee memory e = Employee(true,_status, _name);
        employees[_addr] = e;
        employeeIndex.push(_addr);

        EmployeeCreationEvent();
    }

    // Access an Employee by its address, and returns an event for the DApp
    function accessEmployee(address _addr) external noReentrancy returns(bool) {
        Employee memory e = employees[_addr];
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
        require(paymentIndex.length < 100);
        require(employees[_employee].active);

        uint size;
        address payAddr = paymentContracts[_employee];
        assembly { size := extcodesize(payAddr) }
        Payment p = Payment(payAddr);
        require(size == 0 || !(p.active()));

        // Creating different payment contracts based off the employment types
        Payment _perm = new Payment(owner,_employee,_pay);
        paymentContracts[_employee] = _perm;
        paymentIndex.push(_perm);

        CheckPaymentEvent(paymentContracts[_employee]);
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

        p.setFedTaxable(_addrReturn, _withHold);
        p.setStateTaxable(_addrReturn, _withHold);
        p.setSSTaxable(_addrReturn, _withHold);
        p.setMedicareTaxable(_addrReturn, _withHold);
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
