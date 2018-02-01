pragma solidity ^0.4.16;

/*
    First Concern:
        Classification
        Map employment classification to Tax classification
        Classification
          - Permanent
          - Fulltime
          - Contract
          - Independent
          - Dependent
          - Tax Exempt Employee
          - Non-Tax Exempt Employee
        Many to few
    Second Concern:
        Commit the withholding

*/
contract owned {
    function owned() public { owner = msg.sender; }
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract Mutex {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}


// Associated with in context of US taxing agencies (State)
contract State_BusinessLicensing {
    struct Business {
        int stateTaxID;
        uint recentlyRecordedRevenue;
        uint recentlyRecordedGrowth;
    }
    mapping (address => Business) public businesses;

    function spawnFederalTaxId {
    
    }
}

contract State_CitizenTaxation {
    mapping (address => ) citizens;
    
}

contract Federal_BusinessLicensing {

}