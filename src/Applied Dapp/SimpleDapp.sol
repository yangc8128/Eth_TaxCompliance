program solidity ^0.4.11;

contract owned {
    function owned() public { owner = msg.sender; }
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
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
contract employmentRecord is owned {
    enum EmploymentType {FULL_TIME, PART_TIME, CASUAL, FIXED, CONTRACT, APPRENTICE, TRAIN, COMMISSION, PIECE_RATE};
    struct Employee {
        string employeeFirstName;
        string employeeLastName;
        EmploymentType employmentStatus;
        //uint wage;
    }

    mapping (address => Employee) public employees;
    address[] public employeeAccts;

    mapping (Employee => address) public paymentContracts;

    function setEmployee(address _addr, string _fName, string _lName, EmploymentType, _status, uint _wage) {
        require(employees[_addr].length == 0); // DOES this work?

        Employee e = Employee(_fName, _lName, _status, _wage);
        employees[_addr] = e;

        employeeAccts.push(_addr);
    }
/*
    function getEmployeeWage(address _addr) return (int _wage) {
        return employeeWages[_addr].wage;
    }

    function setEmployeeWage(address _addr, uint _wage) public onlyOwner {
        employeeWages[_addr].wage = _wage;
    }
*/
    // TODO SET PAYMENT METHOD

    function close() public onlyOwner {
        selfdestruct(owner);
    }
}

