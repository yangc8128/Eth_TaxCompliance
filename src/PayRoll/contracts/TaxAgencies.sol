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


contract FedIncomeTax2017 is Taxable {
    uint64 fed_withHold;
    modifier taxableToFed {
        _;
        TaxReport t = TaxReport(taxReportId);
        t.fileTaxItem(TaxReport.TaxType(0), fed_withHold);
    }
    function setFedTaxable(address _addrReturn, uint64 _withHold) public {
        fed_withHold = _withHold;
        taxReportId = _addrReturn;
    }
}

contract StateIncomeTax2017 is Taxable {
    uint64 state_withHold;
    modifier taxableToState {
        _;
        TaxReport t = TaxReport(taxReportId);
        t.fileTaxItem(TaxReport.TaxType(1), state_withHold);
    }
    function setStateTaxable(address _addrReturn, uint64 _withHold) public {
        state_withHold = _withHold;
        taxReportId = _addrReturn;
    }
}

contract SocialSecurityTax2017 is Taxable {
    uint64 SST_withHold;

    modifier taxableToSSA {
        _;
        uint24 annualLimit = 27000;
        TaxReport t = TaxReport(taxReportId);
        uint64 owedSSTax = t.itemizedTaxes(2);
        if (owedSSTax > annualLimit) {
            t.fileTaxItem(TaxReport.TaxType(2), 0);
        } else if (owedSSTax + SST_withHold > annualLimit) {
            t.fileTaxItem(TaxReport.TaxType(2), annualLimit - owedSSTax);
        } else {
            t.fileTaxItem(TaxReport.TaxType(2), SST_withHold);
        }
    }
    function setSSTaxable(address _addrReturn, uint64 _withHold) public {
        SST_withHold = _withHold;
        taxReportId = _addrReturn;
    }
}

contract MedicareTax2017 is Taxable {
    uint64 medi_withHold;

    modifier taxableToMedicare {
        _;
        uint24 taxableMinimum = 20000;
        TaxReport t = TaxReport(taxReportId);
        if (t.itemizedTaxes(3) > taxableMinimum) {
            t.fileTaxItem(TaxReport.TaxType(3), medi_withHold);
        } else {
            t.fileTaxItem(TaxReport.TaxType(3), 0);
        }
    }
    function setMedicareTaxable(address _addrReport, uint64 _withHold) public {
        medi_withHold = _withHold;
        taxReportId = _addrReport;
    }
}