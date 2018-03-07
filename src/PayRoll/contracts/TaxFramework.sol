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
        uint8 entityType;
        //uint32 taxId; // at most a 10 digit number
        bytes32 taxEntityName;
    }

    mapping (address => TaxEntity) public taxEntities;
    mapping (address => address[]) public taxReturns;
    address[] public taxEntityIndex;

    function setTaxEntity(
        address _addr,
        bool _isDomestic,
        bool _isIndividual,
        uint8 _type,
        //uint32 _taxId,
        bytes32 _name
    )
        public
        onlyOwner
    {
        require(!taxEntities[_addr].active);

        TaxEntity memory b = TaxEntity(_isDomestic,_isIndividual,true,_type,_name);
        taxEntities[_addr] = b;
        taxEntityIndex.push(_addr);

        TaxEntityCreation();
    }
    function setTaxReturn(address _taxEntity, address _taxReturn) external {
        require(taxEntities[_taxEntity].active);
        taxReturns[_taxEntity].push(_taxReturn);
    }
    //function updateTaxEntity() public;
    function returnTaxReturn() public constant returns(uint taxOwed, uint taxRefund);
}


// Depends on preexisting Tax Agency
// Recall owner is directly the tax payer
contract TaxReturn is Owned {
    // Modifiable to later updates for the Tax Agencies
    enum TaxType {INCOME,CAPITAL,WINS,DIVIDENDS}

    event FiledTaxItemEvent(
        uint8 taxType,
        uint64 withHolding,
        uint256 dateFiled
    );

    uint16 taxableYear; // x <= 6.55e+3
    uint64 taxOwed; // x <= 1.84e+19
    uint64[4] itemizedTaxes; // Also modifiable for future updates
    address taxAgency;

    function fileTaxItem(TaxType _taxType, uint64 _withHolding) external {
        taxOwed += _withHolding;
        itemizedTaxes[uint8(_taxType)] += _withHolding;

        FiledTaxItemEvent(uint8(_taxType), _withHolding, now);
    }
}


// Depends on preexisting TaxReturn contract
// Recall owner is directly the service provider, or employer
contract Taxable is Owned {
    uint8 taxType;
    uint64 withHolding;
    address taxReturnId;
    address taxAgencyId;

    modifier taxableIncome {
        _;
        // Report withholding
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(TaxReturn.TaxType,uint64)")), TaxReturn.TaxType(taxType), withHolding));
    }

    function Taxable(address _addrReturn, address _addrAgency, uint8 _taxType, uint64 _withHold) public {
        taxReturnId = _addrReturn;
        taxAgencyId = _addrAgency;
        taxType = _taxType;
        withHolding = _withHold;
    }
}
