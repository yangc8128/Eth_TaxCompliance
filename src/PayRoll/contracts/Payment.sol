pragma solidity ^0.4.16;

import "./SafeContract.sol";
import "./SafeMath.sol";
import "./TaxFramework.sol";

contract Payment is Owned, Mutex, Taxable {
    event PaymentCreationEvent( );
    event PaymentEvent (
        bytes8 msg,
        uint256 pay,
        uint256 datePaid,
        uint256 bal
    );

    address employer; address employee;
    uint256 public payPer; uint256 public freq;
    uint256 lastUpdate; uint256 endTime; uint256 owed;
    uint256[] private FREQUENCIES = [0, 0.5 weeks, 1 weeks, 2 weeks, 4 weeks];

    // Considering making it payable
    function Payment(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _endTime
    )
        public
    {
        employer = _employer;
        employee = _employee;
        payPer = _pay;
        freq = FREQUENCIES[_freq]; // Possible error with invalid Frequencies
        endTime = now + _endTime;
        lastUpdate = now;
        owed = 0;
        PaymentCreationEvent();
    }

    // Functions only when payout was previously called
    function withdraw( ) external payable noReentrancy taxableIncome {
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
    function payout( ) external payable noReentrancy taxableIncome {
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

    function setPay( ) internal;
}


contract PermanentPay is Payment {
    function PermanentPay(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq
    )
        Payment(_employer,_employee,_pay, _freq, 0)
        public
    { }

    // Based off of freq
    function setPay( ) internal {
        //uint256 freqCount = (now-lastUpdate)%freq;
        lastUpdate = now;
        owed += payPer;
        //owed += freqCount*payPer;
    }
}
contract CasualPay is Payment {
    function CasualPay(
        address _employer,
        address _employee,
        uint256 _pay
    )
        Payment(_employer,_employee,_pay,0,0)
        public
     { }

    function setPay( ) internal {
        lastUpdate = now;
        owed += payPer;
    }
}
contract ContractPay is Payment {
    function ContractPay(
        address _employer,
        address _employee,
        uint256 _pay,
        uint256 _freq,
        uint256 _endTime
    )
        Payment(_employer,_employee,_pay,_freq,_endTime)
        public 
     { }

    // Based off of freq and contract endTime
    function setPay( ) internal {
        uint256 benchmark = (endTime - now >= 0) ? now : endTime;
        uint256 freqCount = (benchmark-lastUpdate)%freq;
        lastUpdate = now;
        owed += freqCount*payPer;
    }
}
