program solidity ^0.4.11;

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

    enum EmploymentType {PERM, CASUAL, CONTRACT};
    struct Employee {
        string fName;
        string lastName;
        EmploymentType status;
    }

    mapping (address => Employee) public employees;
    address[] public employeeAccts;

    // maps employee address to contract address
    mapping (address => address) public paymentContracts;

    function setEmployee(address _addr, string _fName, string _lName, EmploymentType _status) {
        require(employees[_addr].length == 0); // DOES this work?

        Employee e = Employee(_fName, _lName, _status);
        employees[_addr] = e;

        employeeAccts.push(_addr);
    }

}

