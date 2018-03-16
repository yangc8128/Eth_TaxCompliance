pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
import "./TaxFramework.sol";
import "./TaxAgencies.sol";

// Relationship cannot be split by a library
contract Payment is Owned, Mutex, FedIncomeTax2017, StateIncomeTax2017, SocialSecurityTax2017, MedicareTax2017 {
    event PaymentCreationEvent( );
    event PaymentEvent (
        bytes8 msg,
        uint256 pay,
        uint256 datePaid,
        uint256 bal
    );

    address employer; address employee;
    uint256 public payPer;
    uint256 owed;

    function Payment(
        address _employer,
        address _employee,
        uint256 _pay
    )
        public
    {
        employer = _employer;
        employee = _employee;
        payPer = _pay;
        owed = 0;
        PaymentCreationEvent();
    }

    // Functions only when payout was previously called
    function withdraw( ) external payable noReentrancy {
        // Withdrawal Authorization, Employee
        require(msg.sender == employee);
        require(owed > 0);

        // Money Transfer
        if (owed > this.balance) {
            PaymentEvent("Pending",owed,now,this.balance);
        } else {
            uint balanceBefore = this.balance;
            employee.transfer(owed);
            assert(this.balance == balanceBefore-owed);

            PaymentEvent("Success",owed,now,this.balance);
        }
    }

    // Is required to refill a Payment contract for the Employee to withdraw
    function payout( ) external payable noReentrancy taxableToSSA {
        // Payout Authorization, Employer
        require(msg.sender == employer);
        setPay();
        require(owed > 0);

        // Ensuring that Payment is capable of paying
        if (owed > this.balance) {
            PaymentEvent("Pending",owed,now,this.balance);
        } else {
            PaymentEvent("Applied",owed,now,this.balance);
        }
    }

    function setPay( ) internal {
        owed += payPer;
    }
}

