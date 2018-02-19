pragma solidity ^ 0.4.0;
library SearchLib {
    function getIndexOf(uint[] storage selfStore, uint value) public returns(uint) {
        for (uint n = 0; n < selfStore.length; n++) {
            if (selfStore[n] == value) {
                return n;
            }
        }
        return uint(-1);
    }
}

contract Cont {
    using SearchLib for uint[];
    uint[] libData;

    function append(uint value) public {
        libData.push(value);
    }

    function replace(uint _oldData, uint _newData) public {
        // Will perform library function call
        uint index = libData.getIndexOf(_oldData);
        if (index == uint(-1))
            libData.push(_newData);
        else
            libData[index] = _newData;
    }
}

/*************************************************************************************/

// Same code as before, only no comments
//pragma solidity ^ 0.4.11;
library SetLib {
    struct LibData {
        mapping(uint => bool) flagsMapping;
    }

    function insertData(LibData storage selfStore, uint value) public returns(bool) {
        if (selfStore.flagsMapping[value])
            return false;
        selfStore.flagsMapping[value] = true;
        return true;
    }

    function removeData(LibData storage selfStore, uint value) public returns(bool) {
        if (!selfStore.flagsMapping[value])
            return false;
        selfStore.flagsMapping[value] = false;
        return true;
    }

    function contains(LibData storage selfStore, uint value) public returns(bool) {
        return selfStore.flagsMapping[value];
    }
}

contract Cont1 {
    SetLib.LibData valuesKnown;

    function registerData(uint value) public {
        // Here, all variables of type Set.Data have
        // corresponding member functions.
        // The following function call is identical to
        // Set.insert(knownValues, value)
        require(SetLib.insertData(valuesKnown, value));
    }
}

/*************************************************************************************/

//pragma solidity ^ 0.4.11;
library SetLib1 {
    // This will define a whole new struct data type which is going
    // to be used for holding its data inside the calling contract.
    struct LibData {
        mapping(uint => bool) flagsMapping;
    }
    // Notice how the first parameter's type is "storage
    // reference" therefore it is only its storage address instead of
    // its contents being passed along with the call. That is the
    // Library functions' special feature. Calling the first
    // parameter "selfStore" is idiomatic, if it happens so that the
    // function can be seen as that object's.
    function insertData(LibData storage selfStore, uint value) public returns(bool) {
        if (selfStore.flagsMapping[value])
            return false; // is already there
        selfStore.flagsMapping[value] = true;
        return true;
    }

    function removeData(LibData storage selfStore, uint value) public returns(bool) {
        if (!selfStore.flagsMapping[value])
            return false; // is not there
        selfStore.flagsMapping[value] = false;
        return true;
    }

    function contains(LibData storage selfStore, uint value) public returns(bool) {
        return selfStore.flagsMapping[value];
    }
}

contract Cont2 {
    SetLib1.LibData valuesKnown;

    function registerData(uint value) public {
        // The functions of the library may be called without a
        // certain instance of the library, because the
        // "instance" is going to be the current contract.
        require(SetLib1.insertData(valuesKnown, value));
    }
    // Inside this contract, it's possible to directly access valuesKnown.flagsMapping too, in case we want.
}

/*************************************************************************************/

//pragma solidity ^ 0.4.0;
library IntBig {
    struct IntBig {
        uint[] currentLimbs;
    }

    function fromUint(uint var1) internal returns(IntBig r) {
        r.currentLimbs = new uint[](1);
        r.currentLimbs[0] = var1;
    }

    function add(IntBig _var1, IntBig _var2) internal returns(IntBig r) {
        r.currentLimbs = new uint[](max(_var1.currentLimbs.length, _var2.currentLimbs.length));
        uint carry = 0;
        for (uint i = 0; i < r.currentLimbs.length; ++i) {
            uint var1 = currentLimb(_var1, i);
            uint var2 = currentLimb(_var2, i);
            r.currentLimbs = var1 + var2 + carry;
            if (var1 + var2 < var1 || (var1 + var2 == uint(-1) && carry > 0))
                carry = 1;
            else
                carry = 0;
        }
        if (carry > 0) {
            // too bad, we have to add var1 currentLimb
            uint[] memory newerLimbs = new uint[](r.currentLimbs.length + 1);
            for (i = 0; i < r.currentLimbs.length; ++i) {
                newerLimbs = r.currentLimbs;
            }
            newerLimbs = carry;
            r.currentLimbs = newerLimbs;
        }
    }

    function currentLimb(IntBig _var1, uint _limb) internal returns(uint) {
        return _limb < _var1.currentLimbs.length ? _var1.currentLimbs[_limb] : 0;
    }

    function max(uint var1, uint var2) private returns(uint) {
        return var1 > var2 ? var1 : var2;
    }
}
contract Cont3 {
    using IntBig for IntBig.IntBig;

    function f() public {
        var var1 = IntBig.fromUint(7);
        var var2 = IntBig.fromUint(uint(-1));
        var var3 = var1.add(var2);
    }
}