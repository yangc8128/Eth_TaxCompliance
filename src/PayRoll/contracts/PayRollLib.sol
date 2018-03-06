pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";

library EmployeeMap {
    enum EmploymentType {OWNER, PERM, CASUAL, CONTRACT}
    struct Employee {
        bool active;
        EmploymentType status;
        bytes16 fName;
        bytes16 lName;
    }
    struct Data {
        // maps employee address to a employee struct
        mapping (address => Employee) employees;
        address[] employeeIndex;
    }

    function getMap(Data storage self, address _addr) internal constant returns(Employee employee) {
        return self.employees[_addr];
    }

    function getIndex(Data storage self, uint _index) internal constant returns(address _addr) {
        return self.employeeIndex[_index];
    }

    function insert(
        Data storage self,
        EmploymentType _status,
        bytes16 _fName,
        bytes16 _lName,
        address _addr
    )
        public
    {
        require(self.employees[_addr].active == false);

        // Creating new Employee and recording the address
        Employee memory e = Employee(true,_status, _fName, _lName);
        self.employees[_addr] = e;
        self.employeeIndex.push(_addr);
    }

    function updateEmployeeActiveFlag(Data storage self, address _employee, bool _active) internal {
        self.employees[_employee].active = _active;
    }

    function updateEmployeeStatus(Data storage self, address _employee, EmploymentType _status) internal {
        self.employees[_employee].status = _status;
    }

    function getEmployeeCount(Data storage self) public constant returns(uint256 _length) {
        return self.employeeIndex.length;
    }

    function requireActiveEmpl(Data storage self, address _addr) public view {
        require(self.employees[_addr].active);
    }
}

library PaymentContractMap {
    struct Data {
        // maps employee address to contract address
        mapping (address => address) paymentContracts;
        address[] paymentIndex;
    }

    function insert(Data storage self, address _employee, address _contract) internal {
        self.paymentContracts[_employee] = _contract;
        self.paymentIndex.push(_contract);
    }

    function getCount(Data storage self) public constant returns(uint256 _length) {
        return self.paymentIndex.length;
    }

    function getMap(Data storage self, address _employee) public constant returns(address _addr) {
        return self.paymentContracts[_employee];
    }

    function getIndex(Data storage self, uint _index) public constant returns(address _addr) {
        return self.paymentIndex[_index];
    }

    function requireSmallPayIndex(Data storage self, uint _length) public view {
        require(self.paymentIndex.length < _length);
    }
}

