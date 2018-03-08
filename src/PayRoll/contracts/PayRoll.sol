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
        uint8 _taxType,
        uint64 _withHold,
        uint256 _pay,
        uint256 _freq,
        uint256 _end
    )
        public
        onlyOwner
    {
        createPayment(_employee,_pay,_freq,_end);
        setTaxes(_employee,_addrReturn,_taxType,_withHold);
    }

    // Consider making payable for during creation
    function createPayment(
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _end
    )
        internal
    {
        require(paymentIndex.length < 100);
        require(employees[_employee].active);

        // Using EVM assembly code to check active/unactive contract: https://stackoverflow.com/questions/37644395/how-to-find-out-if-an-ethereum-address-is-a-contract
        uint size;
        address payAddr = paymentContracts[_employee];
        assembly { size := extcodesize(payAddr) }
        Payment p = Payment(payAddr);
        require(size == 0 || !(p.active()));

        var _status = employees[_employee].status;

        // Creating different payment contracts based off the employment types
        if (_status == EmploymentRecord.EmploymentType.PERM || _status == EmploymentRecord.EmploymentType.OWNER) {
            PermanentPay _perm = new PermanentPay(owner,_employee,_pay,_freq);
            paymentContracts[_employee] = _perm;
            paymentIndex.push(_perm);
        } else if (_status == EmploymentRecord.EmploymentType.CASUAL) {
            CasualPay _casual = new CasualPay(owner,_employee,_pay);
            paymentContracts[_employee] = _casual;
            paymentIndex.push(_casual);
        } else if (_status == EmploymentRecord.EmploymentType.CONTRACT) {
            ContractPay _contract = new ContractPay(owner,_employee,_pay,_freq,_end);
            paymentContracts[_employee] = _contract;
            paymentIndex.push(_contract);
        } else {
            revert();
        }
        CheckPaymentEvent(paymentContracts[_employee]);
    }

    function setTaxes(
        address _employee,
        address _addrReturn,
        uint8 _type,
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

        p.setTaxable(_addrReturn, _type, _withHold);
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
