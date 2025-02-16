// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    bool public paused;
    
    mapping(address => uint256) public nonces;
    
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        uint256 initialSupply = 100 ether;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    function pause() external onlyOwner {
        paused = true;
    }
    
    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash)
        );
    }
    
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline);
        
        uint256 currentNonce = nonces[owner_];
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner_,
                spender,
                value,
                currentNonce,
                deadline
            )
        );
        bytes32 digest = _toTypedDataHash(structHash);
        address recovered = ecrecover(digest, v, r, s);
        require(recovered != address(0) && recovered == owner_);
        
        nonces[owner_] = currentNonce + 1;
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}
