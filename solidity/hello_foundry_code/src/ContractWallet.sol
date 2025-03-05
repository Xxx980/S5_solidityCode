pragma solidity ^0.8.0;

contract MultiSigWallet {
    // 存储多签持有人列表和是否是持有人的映射
    address[] public owners;
    mapping(address => bool) public isOwner;
    // 签名门槛
    uint public required;
    
    // 提案结构体
    struct Proposal {
        address to;              // 目标地址
        uint value;              // 转账金额
        bytes data;              // 调用数据（可选）
        bool executed;           // 是否已执行
        uint confirmations;      // 已确认数量
    }
    
    // 存储所有提案
    Proposal[] public proposals;
    // 记录每个提案的确认情况
    mapping(uint => mapping(address => bool)) public confirmations;
    
    // 事件定义
    event ProposalSubmitted(uint index, address to, uint value, bytes data);
    event ProposalConfirmed(uint index, address owner);
    event ProposalExecuted(uint index);
    
    // 构造函数：初始化持有人列表和签名门槛
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required number of owners");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            // 检查重复持有人
            for (uint j = 0; j < i; j++) {
                require(_owners[j] != owner, "duplicate owner");
            }
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }
    
    // 提交提案
    function submitProposal(address _to, uint _value, bytes memory _data) public {
        require(isOwner[msg.sender], "not owner");
        uint index = proposals.length;
        proposals.push(Proposal({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        emit ProposalSubmitted(index, _to, _value, _data);
    }
    
    // 确认提案
    function confirmProposal(uint _index) public {
        require(isOwner[msg.sender], "not owner");
        require(_index < proposals.length, "invalid proposal");
        require(!proposals[_index].executed, "already executed");
        require(!confirmations[_index][msg.sender], "already confirmed");
        confirmations[_index][msg.sender] = true;
        proposals[_index].confirmations += 1;
        emit ProposalConfirmed(_index, msg.sender);
    }
    
    // 执行提案
    function executeProposal(uint _index) public {
        require(_index < proposals.length, "invalid proposal");
        Proposal storage proposal = proposals[_index];
        require(proposal.confirmations >= required, "not enough confirmations");
        require(!proposal.executed, "already executed");
        require(address(this).balance >= proposal.value, "insufficient balance");
        proposal.executed = true;
        if (proposal.data.length > 0) {
            (bool success, ) = proposal.to.call{value: proposal.value}(proposal.data);
            require(success, "transaction failed");
        } else {
            (bool success, ) = proposal.to.call{value: proposal.value}("");
            require(success, "transfer failed");
        }
        emit ProposalExecuted(_index);
    }
    
    // 查询提案信息
    function getProposal(uint _index) public view returns (
        address to,
        uint value,
        bytes memory data,
        bool executed,
        uint confirmationCount
    ) {
        require(_index < proposals.length, "invalid proposal");
        Proposal memory proposal = proposals[_index];
        return (
            proposal.to,
            proposal.value,
            proposal.data,
            proposal.executed,
            proposal.confirmations
        );
    }
    
    // 查询某持有人对提案的确认状态
    function getConfirmationStatus(uint _index, address _owner) public view returns (bool) {
        require(_index < proposals.length, "invalid proposal");
        return confirmations[_index][_owner];
    }
    
    // 接收以太币
    receive() external payable {}
}


