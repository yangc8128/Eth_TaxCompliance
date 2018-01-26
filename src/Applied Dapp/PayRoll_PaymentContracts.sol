pragma solidity ^0.4.11;

contract Payment is owned {
    event PaymentCreationEvent (
      address owner,
      address receiver,
      uint payInDollars
    );

    // https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
    event PaymentEvent (
      address owner,
      address receiver,
      uint payInDollars,
      uint datePaid // LOOK INTO FURTHER (timestamp, now)
    );

    uint constant MONTHLY = 2629743;
    uint constant WEEKLY = 604800;
    uint constant SEMI_MONTHLY = 1314871;
    uint constant BI_WEEKLY = 302400;

    // Contract members
    address receiver;
    // Representative of onetime/wage/salary pay
    uint payInDollars;
    uint lastUpdate;
    bool payCondition = false;

    function Payment(address _receiver, uint _pay) public {
      receiver = _receiver;
      payInDollars = _pay;
      lastUpdate = now;

      PaymentCreationEvent(owner,_receiver,_pay);
    }

    function setPayCondition() public;

    function payout() public onlyOwner {
        if (!payCondition) revert(); // Return gas
        // take from owner
        // send to owner

        PaymentEvent(owner,receiver,payInDollars,now);
    }

}


contract PermanentPay is Payment {
    uint payFrequency;

    // http://solidity.readthedocs.io/en/develop/contracts.html#arguments-for-base-constructors
    function PermanentPay(address _receiver, uint _pay, uint _payFrequency) public Payment(_receiver,_pay) {
      payFrequency = _payFrequency;
    }

    function setPayCondition() public {
        payCondition = true;
    }
}

contract CasualPay is Payment {
    function CasualPay(address _receiver, uint _pay) public Payment(_receiver,_pay) {}

    function setPayCondition() public onlyOwner {
      payCondition = true;
    }
}

contract ContractPay is Payment {
    uint payFrequency;
    uint contractEndTime;

    function ContractPay(address _receiver, uint _pay, uint _payFrequency, uint _endTime) public Payment(_receiver,_pay) {
      contractEndTime = _endTime;
      payFrequency = _payFrequency;
    }

    function setPayCondition() public {
        payCondition = true;
    }

    function earlyTermination() public onlyOwner {
      close();
    }
}
