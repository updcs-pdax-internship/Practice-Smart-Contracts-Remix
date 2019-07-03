pragma solidity ^0.5.0;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/roles/MinterRole.sol";

contract DenominatedToken is MinterRole {
    using SafeMath for uint256;

    uint256 public denominationCount;
    
    //denomination => bool
    mapping (uint256 => bool) public validDenominations;
    //denomination => owner => balances
    mapping (uint256 => mapping(address => uint256)) private _balances;
    //denomination => owner => spender => allowance
    mapping (uint256 => mapping(address => mapping(address => uint256))) private _allowances;
    //denomination => supply;
    mapping (uint256 => uint256) _totalSupply;

    event Transfer(address sender, address recipient, uint256[] denominations, uint256[] amount);
    event Approval(address owner, address spender, uint256[] denominations, uint256[] values);

    constructor(
        uint256 _denominationCount,
        uint256[] memory denominations,
        uint256[] memory initSupply
    ) public {
        require(_denominationCount == denominations.length, "BondToken: denomination count does not match array of denominations.");
        require(denominations.length == initSupply.length, "BondToken: array of denominations does not match array of amount.");

        denominationCount = _denominationCount;
        for (uint256 i = 0; i < denominationCount; i++) {
            validDenominations[denominations[i]] = true;
            _totalSupply[denominations[i]] = initSupply[i];
            _balances[denominations[i]][msg.sender] = initSupply[i];
        }
        // _mint(msg.sender, denominations, initSupply);
    }

    modifier validateDenomination(uint256[] memory denominations) {
        require(denominations.length <= denominationCount, "BondToken: denomination count does not match array of denominations.");
        for (uint256 i = 0; i < denominations.length; i++) {
            require(validDenominations[denominations[i]], "BondToken: denomination not valid.");
        }
        _;
    }

    function totalSupply(uint256 denomination) public view returns(uint256) {
        return _totalSupply[denomination];
    }

    function balanceOf(address account, uint256 denomination) public view returns(uint256) {
        return _balances[denomination][account];
    }

    function allowance(address owner, address spender, uint256 denomination) public view returns (uint256) {
        return _allowances[denomination][owner][spender];
    }

    function mint(address account, uint256[] memory denominations, uint256[] memory amount)
    public
    onlyMinter
    returns (bool) {
        _mint(account, denominations, amount);
        return true;
    }

    function transfer(address recipient, uint256[] memory denominations, uint256[] memory amount) public returns (bool) {
        _transfer(msg.sender, recipient, denominations, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256[] memory denominations, uint256[] memory amount) public returns (bool) {
        _transfer(sender, recipient, denominations, amount);
        for (uint256 i = 0; i < denominations.length; i++) {
            uint256 denomination = denominations[i];
            amount[i] = _allowances[denomination][sender][msg.sender].sub(amount[i]);
        }
        _approve(sender, msg.sender, denominations, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256[] memory denominations, uint256[] memory addedValue)
    public
    validateDenomination(denominations)
    returns (bool) {
        for (uint256 i = 0; i < denominations.length; i++) {
            uint256 denomination = denominations[i];
            addedValue[i] = _allowances[denomination][msg.sender][spender].add(addedValue[i]);
        }
        _approve(msg.sender, spender, denominations, addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256[] memory denominations, uint256[] memory subtractedValue)
    public
    validateDenomination(denominations)
    returns (bool) {
        for (uint256 i = 0; i < denominations.length; i++) {
            uint256 denomination = denominations[i];
            subtractedValue[i] = _allowances[denomination][msg.sender][spender].sub(subtractedValue[i]);
        }
        _approve(msg.sender, spender, denominations, subtractedValue);
        return true;
    }

    function approve(address spender, uint256[] memory denominations, uint256[] memory value) public returns (bool) {
        _approve(msg.sender, spender, denominations, value);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256[] memory denominations,
        uint256[] memory amount
    ) internal validateDenomination(denominations) {
        require(sender != address(0), "BondToken: transfer from the zero address.");
        require(recipient != address(0), "BondToken: transfer to the zero address.");
        require(denominations.length == amount.length, "BondToken: denominations array does not match amount array.");
        
        for(uint256 i = 0; i < denominations.length; i++) {
            uint256 denomination = denominations[i];
            uint256 _amount = amount[i];
            _balances[denomination][sender] = _balances[denomination][sender].sub(_amount);
            _balances[denomination][recipient] = _balances[denomination][recipient].add(_amount);
        }

        emit Transfer(sender, recipient, denominations, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256[] memory denominations,
        uint256[] memory values)
        internal validateDenomination(denominations) {
        require(owner != address(0), "BondToken: transfer from the zero address.");
        require(spender != address(0), "BondToken: transfer to the zero address.");
        require(denominations.length == values.length, "BondToken: denominations array does not match amount array.");

        for (uint256 i = 0; i < denominations.length; i++ ){
            uint256 denomination = denominations[i];
            uint256 value = values[i];
            _allowances[denomination][owner][spender] = value;
        }
        emit Approval(owner, spender, denominations, values);
    }

    function _mint(
        address account,
        uint256[] memory denominations,
        uint256[] memory amount
    ) internal validateDenomination(denominations) {
        require(account != address(0), "BondToken: mint to the zero address.");
        require(denominations.length == amount.length, "BondToken: denominations array does not match amount array.");

        for(uint256 i = 0; i < denominations.length; i++){
            _totalSupply[denominations[i]] = _totalSupply[denominations[i]].add(amount[i]);
            _balances[denominations[i]][account] = _balances[denominations[i]][account].add(amount[i]);
            emit Transfer(address(0), account, denominations, amount);
        }
    }

}
