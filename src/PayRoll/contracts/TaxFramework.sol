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
        bytes32 taxEntityName;
    }

    mapping (address => TaxEntity) public taxEntities;
    mapping (address => address[]) public taxReports;
    address[] public taxEntityIndex;
    uint public taxReportsCount;

    function setTaxEntity(
        address _addr,
        bool _isDomestic,
        bool _isIndividual,
        uint8 _type,
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
        taxReports[_taxEntity].push(_taxReturn);
        taxReportsCount++;
    }
    function indexCount() public constant returns(uint) {
        return taxEntityIndex.length;
    }
    //function updateTaxEntity() public;
    //function returnTaxReturn() public constant returns(uint taxOwed, uint taxRefund);
}


// Depends on preexisting Tax Agency
// Recall owner is directly the tax payer
contract TaxReport is Owned {
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

    function TaxReport(address _agencyAddr, uint16 _taxableYear) public {
        taxAgency = _agencyAddr;
        taxableYear = _taxableYear;
    }

    function fileTaxItem(TaxType _taxType, uint64 _withHolding) external {
        taxOwed += _withHolding;
        itemizedTaxes[uint8(_taxType)] += _withHolding;

        FiledTaxItemEvent(uint8(_taxType), _withHolding, now);
    }
}


// https://ethereum.stackexchange.com/questions/7325/stack-too-deep-try-removing-local-variables
// The stack on Ethereum is only 7 deep

// Depends on preexisting TaxReturn contract
// Recall owner is directly the service provider, or employer
contract Taxable is Owned {
    uint8 taxType;
    uint64 withHolding;
    address taxReturnId;
    //address taxAgencyId;

    modifier taxableIncome {
        _;
        // Report withholding
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(TaxReport.TaxType,uint64)")), TaxReport.TaxType(taxType), withHolding));
    }

    function setTaxable(
        address _addrReturn,
        uint8 _taxType,
        uint64 _withHold
    )
        public
    {
        taxReturnId = _addrReturn;
        taxType = _taxType;
        withHolding = _withHold;
    }
}
