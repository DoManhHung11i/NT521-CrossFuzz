pragma solidity 0.4.26;

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

    function E(Sub _sub) public {
        sub = Sub(_sub);
        owner = msg.sender; 
    }

    function setSub(Sub _sub) public {
        sub = Sub(_sub);
    }


    function setCount(uint _count) public {
        count = _count;
    }

    function setFlag(bool _flag) public {
        flag = _flag;
    }

    function setInner(uint _inner) public {
        inner = _inner;
    }

    function leakEther(address _addr, uint _amount) public {
        _addr.transfer(_amount);
    }

    function lockEther(uint _amount) public {
        sub.addBalances(address(this), _amount); 
    }
    function transactionOrderDependency(address _addr, uint _amount) public {
        sub.addBalances(_addr, _amount); 
    }

    
    function dependencyBlock() public {
        if (block.number < 100) { 
            sub.addBalances(msg.sender, 10 ether);
        }
    }

    function dependency() public {
        if (sub.checkBalance(msg.sender) < 1 ether) {
            revert("Not enough balance");
        }
    }
    function addBalance(address _addr, uint _amount) public {
        sub.addBalances(_addr, _amount);
        count += 1; 
    }

    function withdraw(address _addr, uint _amount) public {
        if (count > 50) {
            revert(); 
        } else {
            count += 2; 
        }
        _addr.transfer(_amount);
    }

    function selfDestructContract() public {
        selfdestruct(owner); 
    }
}
