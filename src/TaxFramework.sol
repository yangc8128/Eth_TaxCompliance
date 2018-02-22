pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
// http://solidity.readthedocs.io/en/develop/layout-of-source-files.html

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
    // Modifiable to later updates for the Tax Agencies
    enum TaxType {INCOME,CAPITAL,WINS,DIVIDENDS}

    event FiledTaxItemEvent(
        uint withHolding,
        uint dateFiled,
        TaxType taxType
    );
    event TaxRebateEvent(
        uint taxOwed,
        uint taxRebate
    );

    address taxpayer;
    uint taxOwed;
    uint taxableYear;
    uint[4] itemizedTaxes; // Also modifiable for future updates

    // Requiring SafeMath
    // https://ethereum.stackexchange.com/questions/25829/meaning-of-using-safemath-for-uint256
    function returnTaxReturn() public view returns(uint, uint) {
        return (taxOwed, SafeMath.absSub(taxOwed,this.balance) );
    }
    // Should this function exist?
    function returnItemizedTaxReturn() external view;
    function fileTaxItem(uint _withHolding, TaxType _type) external {
        FiledTaxItemEvent(_withHolding,now,_type);
    }
    // A Push Payment
    function taxRebate() external payable {
        require(SafeMath.sub(now,taxableYear) >= 1 years);

        uint balanceBefore = this.balance;
        uint rebate = SafeMath.absSub(taxOwed,this.balance);
        taxpayer.transfer(rebate);
        assert(this.balance == SafeMath.sub(balanceBefore,rebate));

        TaxRebateEvent(taxOwed,rebate);
    }
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
        assert(this.balance == SafeMath.sub(balanceBefore,withHolding));

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
