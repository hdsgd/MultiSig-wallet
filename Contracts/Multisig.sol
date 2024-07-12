// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MultiSigWallet {

    /// @notice Este contrato necessita validação e monitoramento continuo
    /// @dev O objetivo deste contrato é executar métodos em outros contratos atráves de validação multipla
    
    /// @notice Eventos disparados quando há operação

    /// @notice Transação a ser executada adicionada
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        bytes data
    );

    /// @notice Transação confirmada
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Transação executada
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Alteração de owner
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequiredA;
    uint256 public numConfirmationsRequiredB;

    struct Transaction {
        address to;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    struct QuorumChange {
        address to;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public confirmationsByUser;

    Transaction[] public transactions;
    QuorumChange[] public quorum;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(
            !confirmationsByUser[_txIndex][msg.sender],
            "tx already confirmed"
        );
        _;
    }

    constructor(
        address[] memory _owners,
        uint256 _numConfirmationsRequiredA,
        uint256 _numConfirmationsRequiredB
    ) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequiredA > 0 &&
                _numConfirmationsRequiredA <= _owners.length,
            "invalid number of required confirmations"
        );
        require(
            _numConfirmationsRequiredB > 0 &&
                _numConfirmationsRequiredB <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequiredA = _numConfirmationsRequiredA;
        numConfirmationsRequiredB = _numConfirmationsRequiredB;
    }

    function submitTransaction(address _to, bytes memory _data)
        public
        onlyOwner
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        confirmationsByUser[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequiredA,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: 0}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function swapOwnerProposal(address _newOwner, address _removeOwner) public onlyOwner{

    }

    function addNewOwnerProposal(address _newOwner) public onlyOwner{

    }
}
