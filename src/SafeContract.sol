pragma solidity ^0.4.18;

contract Owned {
    bool public active;
    address owner;

    function Owned( ) public {
        active = true;
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function getOwner( ) external view returns(address) {return owner;}
    function stop( ) public onlyOwner { active = false; }
    function close( ) public onlyOwner { selfdestruct(owner); }
}


// Used to prevent callback attacks
contract Mutex {
    bool locked;
    modifier noReentrancy( ) {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}