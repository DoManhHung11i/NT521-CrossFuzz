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
    uint internal inner;
}

contract AdditionalContract {
    uint public additionalData;
    
    constructor() public {
        additionalData = 100;
    }

    function increaseData(uint _value) public {
        additionalData += _value;
    }

    function getAdditionalData() public view returns (uint) {
        return additionalData;
    }
}

contract E is Child {
    Sub sub;
    AdditionalContract additionalContract;
    address public owner;
    uint public etherLocked;
    uint public totalWithdrawn;
    uint public randomSeed;
    uint public lastWithdraw;
    bool public isPaused;
    uint public balanceToLock;

    mapping(address => bool) public whitelistedUsers;

    event FundsLocked(address indexed sender, uint amount);
    event FundsWithdrawn(address indexed recipient, uint amount);
    event ContractPaused(bool paused);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelistedUsers[msg.sender], "Not whitelisted");
        _;
    }

    constructor(Sub _sub, AdditionalContract _additionalContract) public {
        sub = _sub;
        additionalContract = _additionalContract;
        owner = msg.sender;
        isPaused = false;
        randomSeed = 100;
        balanceToLock = 0;
    }

    function pauseContract() public onlyOwner {
        isPaused = !isPaused;
        emit ContractPaused(isPaused);
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelistedUsers[_user] = true;
    }

    function removeWhitelistedUser(address _user) public onlyOwner {
        whitelistedUsers[_user] = false;
    }

    function lockFunds(uint _amount) public whenNotPaused onlyWhitelisted {
        etherLocked += _amount;
        emit FundsLocked(msg.sender, _amount);
    }

    function withdrawFunds(address _recipient, uint _amount) public onlyOwner {
        require(etherLocked >= _amount, "Insufficient locked funds");
        etherLocked -= _amount;
        _recipient.transfer(_amount);
        totalWithdrawn += _amount;
        lastWithdraw = now;
        emit FundsWithdrawn(_recipient, _amount);
    }

    function addBalance(address _addr, uint _amount) public {
        sub.addBalances(_addr, _amount);
    }

    function generateRandomNumber() public {
        uint random = uint(blockhash(block.number - 1)) + randomSeed;
        randomSeed = random;
    }

    function getBalance(address _addr) public view returns (uint) {
        return sub.checkBalance(_addr);
    }

    function getContractDetails() public view returns (uint lockedFunds, uint withdrawnFunds, uint randomSeedValue) {
        return (etherLocked, totalWithdrawn, randomSeed);
    }

    function updateAdditionalData(uint _value) public {
        additionalContract.increaseData(_value);
    }

    function getAdditionalContractData() public view returns (uint) {
        return additionalContract.getAdditionalData();
    }

    // Chức năng có lỗ hổng bảo mật không kiểm tra đầu vào
    function unsafeFunction(address _target, uint _amount) public onlyOwner {
        _target.call.value(_amount)("");
    }

    // Lỗ hổng tràn số, khi cộng thêm giá trị quá lớn có thể gây tràn số
    function unsafeAddition(uint _value) public onlyOwner {
        etherLocked += _value;
    }

    // Lỗ hổng kiểm tra tx.origin trong kiểm tra quyền sở hữu
    function restrictedFunction() public view {
        require(tx.origin == owner, "Not the contract owner");
    }

    // Lỗ hổng reentrancy khi gọi hàm rút tiền
    function withdrawWithReentrancy(address _recipient, uint _amount) public onlyOwner {
        uint initialBalance = sub.checkBalance(address(this));

        _recipient.call.value(_amount)("");

        require(sub.checkBalance(address(this)) == initialBalance - _amount, "Reentrancy attack detected");
    }

    // Tạo sự kiện khi rút tiền
    function withdraw(address _recipient, uint _amount) public onlyOwner {
        require(etherLocked >= _amount, "Not enough funds to withdraw");
        etherLocked -= _amount;
        _recipient.transfer(_amount);
        totalWithdrawn += _amount;
        emit FundsWithdrawn(_recipient, _amount);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getLockedFunds() public view returns (uint) {
        return etherLocked;
    }

    function getTotalWithdrawn() public view returns (uint) {
        return totalWithdrawn;
    }

    function getRandomSeed() public view returns (uint) {
        return randomSeed;
    }

    function getContractState() public view returns (bool paused, uint balance) {
        return (isPaused, etherLocked);
    }

    // Phương thức để gửi Ether cho hợp đồng này (chỉ người sở hữu hợp đồng mới có thể gửi)
    function depositFunds() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        etherLocked += msg.value;
    }

    function withdrawEther(uint _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        msg.sender.transfer(_amount);
    }

    // Gọi hàm từ AdditionalContract để tăng giá trị dữ liệu
    function interactWithAdditionalContract() public {
        additionalContract.increaseData(10);
    }

    // Gửi Ether tới một địa chỉ
    function sendEther(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    // Chức năng lấy thông tin hợp đồng
    function getContractInfo() public view returns (uint, uint, uint, uint) {
        return (etherLocked, totalWithdrawn, randomSeed, balanceToLock);
    }
}
