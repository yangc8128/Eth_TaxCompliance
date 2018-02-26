pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";

// Expects a TaxEntity enum for types to be made when implemented
contract TaxAgency is Owned {
    event TaxEntityCreation( );

    struct TaxEntity {
        bool isDomestic;
        bool isIndividual;
        bool active;
        uint entityType;
        uint taxId; // ??
        bytes32 taxEntityName;
    }

    mapping (address => TaxEntity) public taxEntities;
    mapping (address => address[]) public taxReturns;
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
        require(!taxEntities[_addr].active);

        TaxEntity memory b = TaxEntity(_isDomestic,_isIndividual,true,_type,_taxId,_name);
        taxEntities[_addr] = b;
        taxEntityIndex.push(_addr);

        TaxEntityCreation();
    }
    function setTaxReturn(address _taxEntity, address _taxReturn) external {
        require(taxEntities[_taxEntity].active);
        taxReturns[_taxEntity].push(_taxReturn);
    }
    function updateTaxEntity() public;
    function returnTaxReturn() public constant returns(uint taxOwed, uint taxRefund);
}


// Depends on preexisting Tax Agency
contract TaxReturn is Owned {
    // Modifiable to later updates for the Tax Agencies
    enum TaxType {INCOME,CAPITAL,WINS,DIVIDENDS}

    event FiledTaxItemEvent(
        uint withHolding,
        uint dateFiled,
        TaxType taxType
    );

    uint16 taxableYear; // x <= 6.55e+3
    uint64 taxOwed; // x <= 1.84e+19
    uint64[4] itemizedTaxes; // Also modifiable for future updates
    address taxAgency;
    address taxpayer;


}


// Depends on preexisting TaxReturn contract
contract Taxable is Owned {
    event WithHoldingEvent( );

    uint8 taxType;
    uint withHolding;
    address taxReturnId;

    modifier taxableIncome {
        _;
        // Report withholding
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(uint,uint)")), withHolding, taxType));
    }

    function Taxable(address _addr, uint8 _taxType, uint _withHold) public {
        taxReturnId = _addr;
        taxType = _taxType;
        withHolding = _withHold;
    }
}
