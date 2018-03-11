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
    enum TaxType {INCOME,SOCIAL_SECURITY,MEDICARE}//CAPITAL,WINS,DIVIDENDS}

    event FiledTaxItemEvent(
        uint8 taxType,
        uint64 withHolding,
        uint256 dateFiled
    );
    uint8 filingStatus;
    uint16 taxableYear; // x <= 6.55e+3
    uint64 taxOwed; // x <= 1.84e+19
    uint256 public projYearlyIncome;
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

/*
    10%    $0 to $9,325    10% of Taxable Income
    15%    $9,325 to $37,950    $932.50 plus 15% of the excess over $9325
    25%    $37,950 to $91,900    $5,226.25 plus 25% of the excess over $37,950
    28%    $91,900 to $191,650    $18,713.75 plus 28% of the excess over $91,900
    33%    $191,650 to $416,700    $46,643.75 plus 33% of the excess over $191,650
    35%    $416,700 to $418,400    $120,910.25 plus 35% of the excess over $416,700
    39.60%    $418,400+    $121,505.25 plus 39.6% of the excess over $418,400
 */
contract FedIncomeTax2017 is Taxable {
    function taxBracket() internal {
        //uint yearly = taxReturnId.call(bytes4(keccak256("projYearlyIncome()")));
        //uint owed;
        // Figure a way to deal with percentages
        /*
        if (yearly < 9325) {
            owed = 9325 * 0.1;
        } else if (yearly < 37950) {
            owed = taxCalc(932.5,yearly,0.15);
        } else if (yearly < 91900) {
            owed = taxCalc(5226.25,yearly,0.25);
        } else if (yearly < 191650) {
            owed = taxCalc(18713.75,yearly,0.28);
        } else if (yearly < 416700) {
            owed = taxCalc(46643.75,yearly,0.33);
        } else if (yearly < 418400) {
            owed = taxCalc(120910.25,yearly,0.35);
        } else {
            owed = taxCalc(121505.25,yearly,0.396);
        }
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(TaxReport.TaxType,uint64)")), TaxReport.TaxType(taxType), owed));
        */
    }
    function taxCalc(uint owed, uint yearly, rational_const rate) internal returns (uint) {
        // rational const issue
        //https://ethereum.stackexchange.com/questions/21202/solidity-data-types-fixed-and-ufixed
        uint excess = yearly - owed;
        return owed + excess * rate;
    }
    modifier taxableToFed {
        _;
        taxbracket();
    }
}

contract StateIncomeTax2017 is Taxable {
    uint bleh;
}

contract SocialSecurityTax2017 is Taxable {
    modifier taxableToSSA {
        _;
        uint24 annualLimit = 127000;
        uint owedSSTax = taxReturnId.itemizedTaxes(1);
        uint pay = 0;
        if (owedSSTax + pay > annualLimit) {
            pay = annualLimit - owedSSTax;
        }
        assert(taxReturnId.call(bytes4(keccak256("fileTaxItem(TaxReport.TaxType,uint64)")), TaxReport.TaxType(taxType), withHolding));
    }
}

contract MedicareTax2017 is Taxable {
    
}