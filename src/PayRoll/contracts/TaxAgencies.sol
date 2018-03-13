pragma solidity ^0.4.16;

import "./TaxFramework.sol";

// Covers Income Taxes
contract FederalTaxation is TaxAgency {
    // Define Tax Brackets
}

// Covers Sales/Income/Property Taxes
contract StateTaxation is TaxAgency {
    // Define Tax Brackets
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
    function taxBracket() internal pure {
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
    function taxCalc(uint owed, uint yearly, uint rate) internal pure returns (uint) {
        // rational const issue
        //https://ethereum.stackexchange.com/questions/21202/solidity-data-types-fixed-and-ufixed
        uint excess = yearly - owed;
        return owed + excess * rate;
    }
    modifier taxableToFed {
        _;
        taxBracket();
    }
}

contract StateIncomeTax2017 is Taxable {
    uint bleh;
}

contract SocialSecurityTax2017 is Taxable {
    modifier taxableToSSA {
        _;
        uint24 annualLimit = 127000;
        TaxReport t = TaxReport(taxReportId);
        uint64 owedSSTax = t.itemizedTaxes(1);
        uint pay = 0;
        if (owedSSTax + pay > annualLimit) {
            pay = annualLimit - owedSSTax;
        }
        t.fileTaxItem(TaxReport.TaxType(taxType), withHolding);
    }
}

contract MedicareTax2017 is Taxable {
    modifier taxableToMedicare {
        _;/*
        uint24 taxableMinimum = 200000;
        TaxReport t = TaxReport(taxReportId);
        console.log(taxableMinimum);
        console.log(t.taxType);*/
    }
}