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
    CONTRACT
    */
    enum EmploymentType {PERM, CASUAL, TRAIN, AGENCY, CONTRACT};

    // index of created payment contracts
    address[] public paymentContracts;

    function getPaymentContractCount() public constant returns(uint _length) {
        return paymentContracts.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    // https://ethereumdev.io/manage-several-contracts-with-factories/
    function newPayment(EmploymentType _employType) public returns(address _newPayment) {
        // TODO: create contract "Cookie c = new Cookie()"
        //paymentContracts.push(c);
        //return c;
    }
}

