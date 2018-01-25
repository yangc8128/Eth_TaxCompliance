pragma solidity ^0.4.11;

contract Payment is owned {
    event PaymentCreationEvent (
      address owner;
      address receiver;
      uint payInDollars;
    );

    // https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
    event PaymentEvent (
      address owner;
      address receiver;
      uint payInDollars;
      uint datePaid; // LOOK INTO FURTHER (timestamp, now)
    );

    enum PayPeriod {MONTHLY = 2629743, WEEKLY = 604800, SEMIMONTHLY = 1314871, BIWEEKLY = 302400}
    /*
        uint constant monthly = 2629743;
        uint constant weekly = 604800;
        uint constant semimonthly = 1314871;
        uint constant biweekly = 302400;
        uint lastUpdate;
    */

    // Contract members
    address receiver;
    // Representative of onetime/wage/salary pay
    uint payInDollars;
    bool payCondition = false;

    function Payment(address _receiver, uint _pay) {
      receiver = _receiver;
      payInDollars = _pay;

      PaymentCreationEvent(owner,_receiver,_pay);
    }

    function payout() public onlyOwner {
        if (!payCondition) revert(); // Return gas
        // take from owner
        // send to owner

        PaymentEvent(owner,receiver,payInDollars,now);
    }

}


contract PermanentPay is Payment {
    uint payFrequency;
}

contract CasualPay is Payment {
    function setPayCondition public onlyOwner {
      payCondition = true;
    }
}

contract ContractPay is Payment {
    uint contractEndTime;
    uint payFrequency;

    function earlyTermination() public onlyOwner {
      close();
    }
}
