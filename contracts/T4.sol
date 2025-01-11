pragma solidity ^0.4.26;

contract Sub {
    mapping(address => uint) public balances;

    function addBalances(address _addr, uint _amount) public {
        balances[_addr] += _amount;
    }

    function checkBalance(address _addr) public view returns (uint) {
        return balances[_addr];
    }
}

contract Child {
    uint inner;
}

contract E is Child {
    Sub sub;
    uint count;
    bool flag;
    address public owner;
    uint public lastWithdraw;
    uint public totalWithdrawn;
    uint public randomSeed;
    uint public etherLocked;

    address public uninitializedAddress;

    constructor(Sub _sub) public {
        sub = _sub;
        owner = msg.sender;
        count = 0;
        flag = false;
        inner = 0;
        totalWithdrawn = 0;
        lastWithdraw = 0;
        randomSeed = 100;
        etherLocked = 0;
    }

    uint public unnecessaryPublicVar;

    function txOriginAttack() public view returns (address) {
        return tx.origin; 
    }

    function lockEther(uint _amount) public {
        etherLocked += _amount;
    }

    function generateRandomNumber() public {
        uint random = uint(blockhash(block.number - 1)) + randomSeed;
        randomSeed = random;
    }

    function unsafeDelegateCall(address _target, bytes _data) public {
        _target.delegatecall(_data); 
    }

    function uncheckedExternalCall(address _target, bytes _data) public {
        _target.call(_data); 
    }

    function arbitraryFunctionCall(address _target, bytes _data) public {
        _target.call(_data); 
    }

    function withdraw(address _addr, uint _amount) public {
        require(msg.sender == owner, "Unauthorized access");
        _addr.transfer(_amount);
    }


    function withdrawWithReentrancy(address _addr, uint _amount) public {
        uint initialBalance = sub.checkBalance(address(this));

        _addr.call.value(_amount)("");

        require(sub.checkBalance(address(this)) == initialBalance - _amount, "Reentrancy attack detected");
    }

    function gasLimitAttack() public {
        while (true) {
            count++; // Tạo vòng lặp vô tận gây tốn gas
        }
    }

    function selfDestructContract() public {
        require(msg.sender == owner, "Unauthorized");
        selfdestruct(owner); 
    }

    function initializeUninitializedAddress(address _addr) public {
        uninitializedAddress = _addr; 
    }

    function overflowInRandomNumber() public {
        uint random = uint(blockhash(block.number - 1)) + randomSeed;
        randomSeed = random; 
    }

    function unsafeExternalCallWithReentrancy(address _target, bytes _data) public {
        uint initialBalance = sub.checkBalance(address(this));

        _target.call(_data);

        require(sub.checkBalance(address(this)) == initialBalance, "Reentrancy attack detected");
    }

    function unsafeTxOrigin() public view returns (address) {
        address origin = tx.origin; 
        return origin;
    }

    function restrictedFunction() public view {
        require(tx.origin == owner, "Not the contract owner");
    }

    function unsafeContractCall(address _target, bytes _data) public {
        _target.call(_data); 
    }

    function unsafeSendEther(address _recipient, uint _amount) public {
        bool success = _recipient.send(_amount);
        require(success, "Transfer failed");
    }

    function unsafeTransferEther(address _recipient, uint _amount) public {
        _recipient.transfer(_amount); 
    }

    function arbitraryStorageAccess(address _target, uint _value) public {
        _target.call(bytes4(keccak256("setInner(uint256)")), _value); 
    }

    // Tạo lỗ hổng không bảo vệ khi thực thi delegatecall
    function unsafeDelegatecall(address _target, bytes _data) public {
        _target.delegatecall(_data); 
    }

    function infiniteLoopAttack() public {
        while(true) {
            count++; 
        }
    }

    function sendEtherWithoutCheck(address _recipient, uint _amount) public {
        _recipient.transfer(_amount); 
    }
}
