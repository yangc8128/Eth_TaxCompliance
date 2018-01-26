pragma solidity ^0.4.11;

// https://ethereum.stackexchange.com/questions/27777/deploying-contract-factory-structure-in-remix
// https://blog.aragon.one/advanced-solidity-code-deployment-techniques-dc032665f434
contract PaymentFactory is owned {
    enum EmploymentType {PERM, CASUAL, CONTRACT}

    // index of created payment contracts
    address[] public paymentContracts;

    function getPaymentContractCount() public constant returns(uint _length) {
        return paymentContracts.length;
    }

    // function pointer equivalent: https://ethereum.stackexchange.com/questions/3342/pass-a-function-as-a-parameter-in-solidity
    // https://ethereumdev.io/manage-several-contracts-with-factories/
    function createPayment(EmploymentType _status) public onlyOwner returns(address _newPayment) {
        if (_status == PaymentFactory.EmploymentType.PERM) {
            PermanentPay _perm = new PermanentPay();
            paymentContracts.push(_perm);
            return _perm;
        } else if (_status == PaymentFactory.EmploymentType.PERM) {
            CasualPay _casual = new CasualPay();
            paymentContracts.push(_casual);
            return _casual;
        } else if (_status == PaymentFactory.EmploymentType.PERM) {
            ContractPay _contract = new ContractPay();
            paymentContracts.push(_contract);
            return _contract;
        } else {
            revert();
        }
    }
}

