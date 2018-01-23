program solidity ^0.4.11;

contract owned {
    function owned() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

// CHECK THE SECURITY RISKS FIRST!! PROBABLY THE REASON FOR THE DAO HACK
contract Mutex {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}


contract Payment is owned {
    Event PaymentCreationEvent {
      address owner;
      address receiver;
      uint payInDollars;
    }

    Event PaymentEvent {
      address owner;
      address receiver;
      uint payInDollars;
      uint datePaid; // LOOK INTO FURTHER (timestamp, now)
// https://ethereum.stackexchange.com/questions/18192/how-do-you-work-with-date-and-time-on-ethereum-platform
    }

    // Contract members
    address constant owner = 0x000000; // HARD CODED EMPLOYER WALLET
    address receiver;
    uint payInDollars;
    bool payCondition = false; // HARD CODED so that children can initiate pay

    // Does this need to be protected by onlyOwner? Find out
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

    function close() public onlyOwner {
      selfdestruct(owner);
    }
}


contract PermanentPay is Payment {
    uint payFrequency;
}

contract CausalPay is Payment {
    function setPayCondition public onlyOwner {
      payCondition = true;
    }
}

contract TrainingPay is Payment {
    // Maybe needed for automated change in employment status
    // Research viability of empty events
    Event ChangeToPerm {}

    uint payFrequency;
    bool completedTraining = false;

    function setCompletedTraining(bool _cond) public onlyOwner {
        completedTraining = true;
        ChangeToPerm();
    }

    // selfdestruct needs to be triggered be a response of the completion of
    // transition otherwise the transaction would not have been atomic
}

contract ContractPay is Payment {
    uint contractEndTime;
    uint payFrequency;

    function earlyTermination() public onlyOwner {
      close();
    }
}
