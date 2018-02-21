pragma solidity ^0.4.16;

contract Owned {
    function Owned() public { owner = msg.sender; }
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


contract BusinessTaxation is Owned {
    enum BusinessType {CHURCH,LLC}
    event BusinessCreationEvent( );
    struct Business {
        bool isDomestic;
        bool active;
        BusinessType busType;
        uint taxId;
        bytes32 busName;
    }

    // maps business address to a business struct
    mapping (address => Business) public businesses;
    address[] public businessIndex;

    function setBusiness(
        address _addr,
        bool _isDomestic,
        BusinessType _busType,
        uint _taxId,
        bytes32 _busName
    )
        public
        onlyOwner
    {
        require(businesses[_addr].active == false);

        // Creating new Business and recording the address
        Business memory b = Business(_isDomestic,true,_busType,_taxId,_busName);
        businesses[_addr] = b;
        businessIndex.push(_addr);

        BusinessCreationEvent();
    }
    function updateBusiness() public;
}


contract IndividualTaxation is Owned {
    enum IndividualType {RESIDENT,ALIEN}
    struct Individual {
        bool isDomestic;
        bool active;
        IndividualType indivType;
        uint taxId;
        bytes32 indivName;
    }
    mapping (address => Individual) public individuals;
    address[] public individualIndex;

    function setIndividual(
        address _addr,
        bool _isDomestic,
        IndividualType _indivType,
        uint _taxId,
        bytes32 _indivName
    )
        public
        onlyOwner
    {
        //require(employees[_addr].active == false);

        Individual memory b = Individual(_isDomestic,true,_indivType,_taxId,_indivName);
        individuals[_addr] = b;

        individualIndex.push(_addr);

        //IndividualCreation();
    }
    function updateIndividual() public;
    function returnTaxReturn() public constant returns(uint taxOwed, uint taxRefund);
}


contract FederalTaxation is BusinessTaxation, IndividualTaxation {
    
}


contract StateTaxation is BusinessTaxation, IndividualTaxation {
    
}

contract TaxReturn is Owned {
    uint taxOwed;
    uint taxRefund;
    uint taxableYear;
    function returnTaxReturn() public pure returns(uint taxOwed, uint taxRefund) {
        return (taxOwed, taxRefund);
    }
}

contract Taxable is Owned {
    address taxReturnId;
    uint withHolding;
    modifier taxableIncome {
        _;
    }
}