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

    // Lỗ hổng Uninitialized Storage Pointer: Biến storage chưa được khởi tạo đúng cách
    address public uninitializedAddress;

    constructor(Sub _sub) public {
        sub = _sub;
        owner = msg.sender;
        count = 0;
        flag = false;
        inner = 0;
        totalWithdrawn = 0;
        lastWithdraw = 0;
        randomSeed = 100; // Lưu giá trị mặc định
        etherLocked = 0;
    }

    // Lỗ hổng Unnecessary Public State Variables: Biến công khai không cần thiết
    uint public unnecessaryPublicVar;

    // Lỗ hổng Tx.origin Attacks: Lỗi này xảy ra khi sử dụng tx.origin thay vì msg.sender
    function txOriginAttack() public view returns (address) {
        return tx.origin; // Nếu tx.origin là một địa chỉ không phải là người gọi trực tiếp, có thể gây ra tấn công
    }

    // Lỗ hổng Unintentional Ether Locking: Ether có thể bị khóa mà không thể lấy lại
    function lockEther(uint _amount) public {
        etherLocked += _amount; // Ether được "khóa" mà không có cách nào lấy lại
    }

    // Lỗ hổng Insecure Randomness: Các giá trị ngẫu nhiên có thể bị đoán trước nếu dựa vào blockhash hoặc timestamp
    function generateRandomNumber() public {
        uint random = uint(blockhash(block.number - 1)) + randomSeed;
        randomSeed = random;
    }

    // Lỗ hổng Delegatecall Vulnerabilities: Gọi delegatecall mà không kiểm tra quyền truy cập
    function unsafeDelegateCall(address _target, bytes _data) public {
        _target.delegatecall(_data); // Việc không kiểm tra đối tượng và dữ liệu có thể dẫn đến các hành động không mong muốn
    }

    // Lỗ hổng Unchecked External Call: Gọi các hàm bên ngoài mà không kiểm tra sự thành công
    function uncheckedExternalCall(address _target, bytes _data) public {
        _target.call(_data); // Không kiểm tra kết quả của cuộc gọi có thể dẫn đến các cuộc tấn công
    }

    // Lỗ hổng Arbitrary Function Call: Cho phép gọi các hàm bên ngoài hợp đồng
    function arbitraryFunctionCall(address _target, bytes _data) public {
        _target.call(_data); // Cho phép gọi hàm không kiểm tra, có thể dẫn đến việc thi hành mã độc
    }

    // Lỗ hổng Access Control: Không có kiểm tra quyền truy cập, chức năng có thể bị lạm dụng
    function withdraw(address _addr, uint _amount) public {
        require(msg.sender == owner, "Unauthorized access");
        _addr.transfer(_amount);
    }

    // Lỗ hổng Reentrancy với External Call: Gọi hàm bên ngoài mà không có bảo vệ reentrancy
    function withdrawWithReentrancy(address _addr, uint _amount) public {
        uint initialBalance = sub.checkBalance(address(this));

        _addr.call.value(_amount)("");

        require(sub.checkBalance(address(this)) == initialBalance - _amount, "Reentrancy attack detected");
    }

    // Lỗ hổng Gas Limit Attack: Vòng lặp vô tận có thể làm tốn gas và tấn công hợp đồng
    function gasLimitAttack() public {
        while (true) {
            count++; // Tạo vòng lặp vô tận gây tốn gas
        }
    }

    // Lỗ hổng Selfdestruct Attack: Có thể bị phá hủy mà không có bảo vệ quyền truy cập
    function selfDestructContract() public {
        require(msg.sender == owner, "Unauthorized");
        selfdestruct(owner); // Hủy hợp đồng mà không có kiểm tra an toàn
    }

    // Lỗ hổng Uninitialized Storage: Thực thể chưa được khởi tạo đúng
    function initializeUninitializedAddress(address _addr) public {
        uninitializedAddress = _addr; // Không kiểm tra _addr hợp lệ có thể dẫn đến dữ liệu không chính xác
    }

    // Lỗ hổng Integer Overflow trong Randomness: Tạo số ngẫu nhiên mà không kiểm tra overflow
    function overflowInRandomNumber() public {
        uint random = uint(blockhash(block.number - 1)) + randomSeed;
        randomSeed = random; // Nếu randomSeed quá lớn, có thể xảy ra tràn số
    }

    // Lỗ hổng Unsafe External Call: Gọi một hợp đồng bên ngoài mà không có kiểm tra lỗi
    function unsafeExternalCallWithReentrancy(address _target, bytes _data) public {
        uint initialBalance = sub.checkBalance(address(this));

        // Kẻ tấn công có thể lợi dụng nếu _target là một hợp đồng không an toàn
        _target.call(_data);

        require(sub.checkBalance(address(this)) == initialBalance, "Reentrancy attack detected");
    }

    // Lỗ hổng tx.origin trong hàm không an toàn
    function unsafeTxOrigin() public view returns (address) {
        address origin = tx.origin; // Có thể bị tấn công từ bên ngoài nếu tx.origin được sử dụng
        return origin;
    }

    // Lỗ hổng sử dụng tx.origin trong kiểm tra quyền truy cập
    function restrictedFunction() public view {
        require(tx.origin == owner, "Not the contract owner");
    }

    // Lỗ hổng gọi hợp đồng không an toàn mà không kiểm tra kết quả
    function unsafeContractCall(address _target, bytes _data) public {
        _target.call(_data); // Không kiểm tra kết quả, có thể gây ra các lỗ hổng bảo mật
    }

    // Lỗ hổng của `send` với sai sót trong kiểm tra kết quả
    function unsafeSendEther(address _recipient, uint _amount) public {
        bool success = _recipient.send(_amount);
        require(success, "Transfer failed");
    }

    // Lỗ hổng trong việc sử dụng transfer mà không có bảo vệ
    function unsafeTransferEther(address _recipient, uint _amount) public {
        _recipient.transfer(_amount); // Không có kiểm tra tình trạng chuyển Ether
    }

    // Tạo lỗ hổng Arbitrary Storage Access
    function arbitraryStorageAccess(address _target, uint _value) public {
        _target.call(bytes4(keccak256("setInner(uint256)")), _value); // Không kiểm tra dữ liệu đầu vào, có thể thay đổi bộ nhớ của hợp đồng khác
    }

    // Tạo lỗ hổng không bảo vệ khi thực thi delegatecall
    function unsafeDelegatecall(address _target, bytes _data) public {
        _target.delegatecall(_data); // Delegatecall có thể dẫn đến việc thay đổi trạng thái của hợp đồng không mong muốn
    }

    // Lỗ hổng trong vòng lặp vô tận khiến hợp đồng không thể thực thi
    function infiniteLoopAttack() public {
        while(true) {
            count++; // Tạo vòng lặp vô tận chiếm hết gas
        }
    }

    // Lỗ hổng khi chuyển Ether mà không có kiểm tra
    function sendEtherWithoutCheck(address _recipient, uint _amount) public {
        _recipient.transfer(_amount); // Không kiểm tra trước khi gửi Ether
    }
}
