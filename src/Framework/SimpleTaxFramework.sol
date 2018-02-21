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


// Expects a TaxEntity enum for types to be made when implemented
contract TaxAgency is Owned {
    event TaxEntityCreation( );

    struct TaxEntity {
        bool isDomestic;
        bool isIndividual;
        bool active;
        uint entityType;
        //uint[] taxIds;
        uint taxId;
        bytes32 taxEntityName;
    }
    /*
    struct TaxReturn {
        uint year;
        address taxReturnId;
    }
    struct TaxReturns {
        TaxReturn[] taxReturns;
    }
    // Consider: Manually filling the parts into memory instead of utilizing a refernce variable
    // https://ethereum.stackexchange.com/questions/12611/solidity-filling-a-struct-array-containing-itself-an-array
    */


    mapping (address => TaxEntity) public taxEntities;
    //mapping (address => address[]) public taxReturns;
    address[] public taxEntityIndex;

    function setTaxEntity(
        address _addr,
        bool _isDomestic,
        bool _isIndividual,
        uint _type,
        uint _taxId,
        bytes32 _name
    )
        public
        onlyOwner
    {
        require(taxEntities[_addr].active == false);

        TaxEntity memory b = TaxEntity(_isDomestic,_isIndividual,true,_type,_taxId,_name);
        taxEntities[_addr] = b;
        taxEntityIndex.push(_addr);

        TaxEntityCreation();
    }
    function updateTaxEntity() public;
    function returnTaxReturn() public constant returns(uint taxOwed, uint taxRefund);
}

//contract FederalTaxation is TaxAgency {}
//contract StateTaxation is TaxAgency {}

//https://ethereum.stackexchange.com/questions/29535/when-to-specify-uint-size
contract TaxReturn is Owned {
    enum TaxType {INCOME,CAPITAL,WINS,DIVIDENDS}

    event FiledTaxItemEvent(
        uint withHolding,
        uint dateFiled,
        TaxType taxType
    );

    uint taxOwed;
    uint taxRefund;
    uint taxableYear;
    uint[4] itemizedTaxes;

    // Requiring SafeMath
    function returnTaxReturn() public view returns(uint, uint) {
        return (taxOwed, abs(taxOwed - this.balance) );
    }
    // Should this function exist?
    function returnItemizedTaxReturn() external view;
    function fileTaxItem(uint _withHolding, TaxType _type) external {
        FiledTaxItemEvent(_withHolding,now,_type);
    }
    function taxRebate() external payable;
}

contract Taxable is Owned {
    event WithHoldingEvent( );

    address taxReturnId;
    uint taxType;
    uint withHolding;

    modifier taxableIncome {
        _;
        // Sending withholding amount
        uint balanceBefore = this.balance;
        taxReturnId.transfer(withHolding);
        assert(this.balance == balanceBefore-withHolding);

        // Report withholding
        // https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices
        // http://solidity.readthedocs.io/en/develop/types.html#members-of-addresses
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(uint,uint)")), withHolding, taxType));
    }

    function Taxable(address _addr, uint _taxType, uint _withHold) public {
        taxReturnId = _addr;
        taxType = _taxType;
        withHolding = _withHold;
    }
}