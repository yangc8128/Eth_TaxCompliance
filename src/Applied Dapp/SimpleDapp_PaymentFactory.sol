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

// https://ethereum.stackexchange.com/questions/27777/deploying-contract-factory-structure-in-remix
// https://blog.aragon.one/advanced-solidity-code-deployment-techniques-dc032665f434
contract PaymentFactory is owned {
    /*
    PERM = Permanent(Full-time, Part-Time) / Fixed
    CASUAL
    TRAIN = Apprentice / Trainees
    // Removed for simplicity since the difficulty of making another Dapp that
    // interacts with this one modeling multiple Agency Staffing Firms
    //AGENCY = Employment Agency Staff
    CONTRACT
    // Removed for simplicity since the difficulty of adding another contract
    // listening in on additional transactions in daily work environment
    //COMM = Commission
    //PIECE
    */
    enum EmploymentType {PERM, CASUAL, TRAIN, AGENCY, CONTRACT};

    // index of created payment contracts
    address[] public paymentContracts;

    function getPaymentContractCount() public constant returns(uint _length) {
        return paymentContracts.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    function newPayment(EmploymentType _employType) public returns(address _newPayment) {
        // TODO: create contract "Cookie c = new Cookie()"
        //paymentContracts.push(c);
        //return c;
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
