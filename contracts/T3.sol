// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract VulnerableBank {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

   
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Cập nhật lại cách gửi Ether
        msg.sender.transfer(_amount);

        balances[msg.sender] -= _amount;
    }

  
    function addBalance(uint256 _amount) public {
        balances[msg.sender] += _amount;
        // Integer overflow nếu _amount quá lớn
    }


    function donate() public payable {
        require(msg.value > 0, "Must send Ether");

        
        owner.transfer(msg.value);
    }




    function assertFailure() public pure {
        assert(false); 
    }


    function kill() public {
        require(msg.sender == owner, "Not the owner");
        selfdestruct(owner); 
    }
}

contract CrossContractVulnerable {
    VulnerableBank public bank;

    constructor(address _bank) public {
        bank = VulnerableBank(_bank);
    }

    function exploitDelegateCall(address target) public {
        target.delegatecall(abi.encodeWithSignature("donate()"));
    }

    function attackWithdraw(address victim) public {
        bank.deposit.value(1 ether)();
        bank.withdraw(1 ether);
    }

    function leakEther(address recipient) public payable {
        require(msg.value > 0, "No Ether sent");
        recipient.transfer(msg.value); 
    }
}

contract Attack {
    VulnerableBank public bank;
    CrossContractVulnerable public crossContract;

    constructor(address _bank, address _crossContract) public {
        bank = VulnerableBank(_bank);
        crossContract = CrossContractVulnerable(_crossContract);
    }

    function attackReentrancy() public payable {
        require(msg.value > 0, "Send some Ether to attack");

        bank.deposit.value(msg.value)();

        bank.withdraw(msg.value);
    }

    function exploitDelegateCall() public {
        crossContract.exploitDelegateCall(address(bank));
    }

    function causeUnhandledException() public {
        require(false, "This will fail");
    }

    function lockEther(uint256 _amount) public {
        bank.deposit.value(_amount)();
    }
}

contract E {
    VulnerableBank public bank;
    CrossContractVulnerable public crossContract;
    Attack public attacker;

    constructor(address _bank, address _crossContract, address _attacker) public {
        bank = VulnerableBank(_bank);
        crossContract = CrossContractVulnerable(_crossContract);
        attacker = Attack(_attacker);
    }

    function triggerReentrancy() public payable {
        attacker.attackReentrancy.value(msg.value)();
    }

    function triggerDelegateCallExploit() public {
        attacker.exploitDelegateCall();
    }

    function triggerUnhandledException() public {
        attacker.causeUnhandledException();
    }

    function triggerLockEther(uint256 amount) public {
        attacker.lockEther(amount);
    }

    function triggerKill() public {
        bank.kill();
    }
}
