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

/*
 * If there is a need to reuse a identification number
 * there is no need to copy it, just set it from a function
 */

// Associated with in context of US taxing agencies (State)
contract StateBusinessLicensing is Owned {
    enum BusinessType {CHURCH,LLC}
    struct Business {
        uint stateTaxId;
        bool isDomestic;
        BusinessType busType;
    }
    mapping (address => Business) public businesses;
    address[] public businessIndex;

    function setBusiness(
        address _addr,
        uint _stateTaxId,
        bool _isDomestic,
        BusinessType _busType
    )
        public
        onlyOwner
    {
    
        Business memory b = Business(_stateTaxId, _isDomestic, _busType);
        businesses[_addr] = b;

        businessIndex.push(_addr);
    }
}

/*
 * Taxable Entity:
 * Must have an ID
 * Must have a boolean determining Domestic/Foreign
 * Must have a Type
 */
contract CitizenTaxation is Owned {
    struct Citizen {
        int individualTaxId;
        bool isDomestic;
    }
    mapping (address => Citizen) citizens;
    address[] public citizenIndex;

    function setCitizen(
        address _addr,
        int _individualTID,
        bool _isDomestic
    )
        public
        onlyOwner
    {
        Citizen memory c = Citizen(_individualTID,_isDomestic);
        citizens[_addr] = c;

        citizenIndex.push(_addr);
    }
}

// Employer Identification Numner
contract FederalBusinessLicensing {

}