program solidity ^0.4.18

// Note on keywords view / pure: https://ethereum.stackexchange.com/questions/25200/solidity-what-is-the-difference-between-view-and-constant

contract Courses {

    struct Instructor {
        uint age;
        string fName;
        string lName;
    }

    // How to access the instructors
    mapping (address => Instructor) instructors;
    // How to know if it already exists
    address[] public instructorAccts;

    function setInstructor(address _addr, uint _age, string _fName, string _lName) public {
        var instructor = instructors[_addr];

        instructor.age = _age;
        instructor.fName = _fName;
        insturctor.lName = _lName;

        instructorAccts.push(_addr) -1;
    }

    function getInstructors() view public returns (address[]) {
        return instructorsAccts;
    }

    function getInstructor(address _ins) view public return (uint, string, string) {
        return (instructors[_ins].age, instructors[_ins].fName, instructors[_ins].lName;
    }

    function countInstructors() view public returns (uint) {
        return instructorAccts.length;
    }
}