// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Carteira Multisig para execução de operações em contratos
/// @author Gustavo Henrique / gustavohenrisantos@gmail.com
/// @notice MultiSigWallet
contract MultiSigWallet {
    /// @notice Este contrato necessita validação e monitoramento continuo
    /// @dev O objetivo deste contrato é executar métodos em outros contratos atráves de validação multipla
    /// @dev Para efeitos de confirmação utilizei somente confirmação de um único owner para alterar os owners e o número mínimo de confirmações

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
    event OwnerChanged(address indexed newOwner);

    /// @notice Array de votantes
    address[] public owners;
    /// @notice Mapping para verificação de se wallet é votante
    mapping(address => bool) public isOwner;
    /// @notice Número de confirmações necessárias
    uint256 public numConfirmationsRequired;

    /// @notice Modelo de transação usado para criar uma chamada
    struct Transaction {
        address to;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    /// @notice Checagem de confirmação de uma proposta usando índice e carteira votante
    mapping(uint256 => mapping(address => bool)) public confirmationsByUser;

    Transaction[] public transactions;

     /**
     * @dev Modificador para averiguar propriedade do contrato. Revete
     * em caso de falha.
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Authorized");
        _;
    }

    /**
     * @dev Modificador para averiguar se proposta de transação já existe. Reverte
     * em caso de transação  não encontrada.
     */
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "TX does not exist");
        _;
    }

    /**
     * @dev Modificador para averiguar se proposta ja foi executada. Reverte
     * em caso de transação já executada.
     */
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "TX already executed");
        _;
    }

    /**
     * @dev Modificador para averiguar se propriedade ja foi confirmada. Reverte
     * em caso de transação já confirmada.
     */
    modifier notConfirmed(uint256 _txIndex) {
        require(
            !confirmationsByUser[_txIndex][msg.sender],
            "TX already confirmed"
        );
        _;
    }

     /**
     * @dev Definição de parametros :
     *  {_owners} -> Array de votantes
     *  {_numConfirmationsRequired} -> Número de confirmações necessárias para aprovação
     *
     */

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /// @notice Método para submeter nova transação
    /// @param _to Endereço para onde será executado
    /// @param _data Data para ser executado , exemplo em contrato anexo ERC20 getPauseData()   
    /// @dev É necessário que o número mínimo de aprovações seja atingido
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

    /// @notice Método para confirmar nova transação , voto
    /// @param _txIndex Índice da proposta de votação
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

    /// @notice Método para executar transação
    /// @param _txIndex Índice da proposta de votação
    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: 0}(transaction.data);
        require(success, "TX failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// @notice Método para retornar array de votantes
    /// @return Array de votantes

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @notice Método para retornar quantidade de propostas
    /// @return Uint de quantidade
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /// @notice Método para retornar quantidade de propostas
    /// @param _txIndex Índice da proposta de votação
    /// @return to endereço de execução da transação proposta
    /// @return data Data a ser executado ou executado
    /// @return executed Bool de confirmação de execução de transação false -> não executada
    /// @return numConfirmations Número de confirmações já realizadas
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

    /// @notice Método para troca de carteiras votantes
    /// @param _newOwner Novo votante
    /// @param _removeOwner Votante a ser removido
    function swapOwner(address _newOwner, address _removeOwner)
        public
        onlyOwner
    {
        require(_newOwner != address(0), "Invalid owner");
        require(!isOwner[_newOwner], "Owner not unique");
        require(isOwner[_removeOwner], "Owner not found");
        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        emit OwnerChanged(_newOwner);
    }

    /// @notice Método para adição de carteira votante
    /// @param _newOwner Novo votante
    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid owner");
        require(!isOwner[_newOwner], "Owner not unique");
        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        emit OwnerChanged(_newOwner);
    }

    /// @notice Método para alteração de número mínimo de confirmações
    /// @param _newValue Número de aprovações necessárias
    function updateConfirmationsRequired(uint256 _newValue) public onlyOwner {
        require(
            numConfirmationsRequired > 0 &&
                numConfirmationsRequired <= owners.length,
            "invalid number of required confirmations"
        );
        numConfirmationsRequired = _newValue;
    }
}
