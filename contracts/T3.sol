// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract VulnerableBank {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // Lỗi Reentrancy
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Lỗi Reentrancy (Rút tiền không an toàn)
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Cập nhật lại cách gửi Ether
        msg.sender.transfer(_amount);

        balances[msg.sender] -= _amount;
    }

    // Lỗi Integer Overflow
    function addBalance(uint256 _amount) public {
        balances[msg.sender] += _amount;
        // Integer overflow nếu _amount quá lớn
    }

    // Lỗi gửi tiền không kiểm tra điều kiện
    function donate() public payable {
        require(msg.value > 0, "Must send Ether");

        // Lỗi: gửi Ether mà không kiểm tra
        owner.transfer(msg.value);
    }



    // Lỗi Assertion Failure
    function assertFailure() public pure {
        assert(false); // Gây lỗi vì điều kiện không thỏa mãn
    }

    // Lỗi Unprotected Self-Destruct
    function kill() public {
        require(msg.sender == owner, "Not the owner");
        selfdestruct(owner); // Không kiểm soát việc tự hủy hợp đồng
    }
}

contract CrossContractVulnerable {
    VulnerableBank public bank;

    constructor(address _bank) public {
        bank = VulnerableBank(_bank);
    }

    // Lỗi Delegatecall không an toàn
    function exploitDelegateCall(address target) public {
        target.delegatecall(abi.encodeWithSignature("donate()"));
    }

    // Lỗi Transaction Order Dependency (Tấn công phụ thuộc thứ tự giao dịch)
    function attackWithdraw(address victim) public {
        bank.deposit.value(1 ether)();
        bank.withdraw(1 ether);
    }

    // Lỗi Leaking Ether
    function leakEther(address recipient) public payable {
        require(msg.value > 0, "No Ether sent");
        recipient.transfer(msg.value); // Gửi Ether mà không kiểm tra điều kiện bảo mật
    }
}

contract Attack {
    VulnerableBank public bank;
    CrossContractVulnerable public crossContract;

    constructor(address _bank, address _crossContract) public {
        bank = VulnerableBank(_bank);
        crossContract = CrossContractVulnerable(_crossContract);
    }

    // Reentrancy Attack
    function attackReentrancy() public payable {
        require(msg.value > 0, "Send some Ether to attack");

        // Gửi Ether để bắt đầu cuộc tấn công Reentrancy
        bank.deposit.value(msg.value)();

        // Rút tiền để kích hoạt Reentrancy
        bank.withdraw(msg.value);
    }

    // Delegatecall Exploit
    function exploitDelegateCall() public {
        crossContract.exploitDelegateCall(address(bank));
    }

    // Lỗi Unhandled Exception
    function causeUnhandledException() public {
        require(false, "This will fail");
    }

    // Lock Ether (Chặn việc rút Ether)
    function lockEther(uint256 _amount) public {
        bank.deposit.value(_amount)();
        // Không thể rút Ether vì điều kiện không hợp lý
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

    // Kích hoạt cuộc tấn công Reentrancy
    function triggerReentrancy() public payable {
        attacker.attackReentrancy.value(msg.value)();
    }

    // Kích hoạt cuộc tấn công Delegatecall Exploit
    function triggerDelegateCallExploit() public {
        attacker.exploitDelegateCall();
    }

    // Gây lỗi Unhandled Exception
    function triggerUnhandledException() public {
        attacker.causeUnhandledException();
    }

    // Thực hiện tấn công Lock Ether
    function triggerLockEther(uint256 amount) public {
        attacker.lockEther(amount);
    }

    // Gọi hàm tự hủy hợp đồng
    function triggerKill() public {
        bank.kill();
    }
}
