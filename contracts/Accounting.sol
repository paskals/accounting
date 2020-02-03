/**
    @title: Accounting
    @dev: various base contracts with accounting functionality
    @author: Paskal S
 */

pragma solidity >=0.5.0 <0.6.0;

import "../lib/math-lib.sol";
import "../lib/erc20.sol";

/**
 a base contract with accounting functionality for ETH and ERC20 tokens
 */
contract Accounting {

    using DSMath for uint;

    bool internal _in;
    
    modifier noReentrance() {
        require(!_in, "Reentrance not allowed!");
        _in = true;
        _;
        _in = false;
    }
    
    //keeping track of total ETH and token balances
    uint public totalETH;
    mapping (address => uint) public totalTokenBalances;

    struct Account {
        bytes32 name;
        uint balanceETH;
        mapping (address => uint) tokenBalances;
    }

    Account base = Account({
        name: "Base",
        balanceETH: 0       
    });

    event ETHDeposited(bytes32 indexed account, address indexed from, uint value);
    event ETHSent(bytes32 indexed account, address indexed to, uint value);
    event ETHTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, uint value);
    event TokenTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, address indexed token, uint value);
    event TokenDeposited(bytes32 indexed account, address indexed token, address indexed from, uint value);    
    event TokenSent(bytes32 indexed account, address indexed token, address indexed to, uint value);

    function baseETHBalance() public view returns(uint) {
        return base.balanceETH;
    }

    function baseTokenBalance(address token) public view returns(uint) {
        return base.tokenBalances[token];
    }

    function depositETH(Account storage a, address _from, uint _value) internal {
        a.balanceETH = a.balanceETH.add(_value);
        totalETH = totalETH.add(_value);
        emit ETHDeposited(a.name, _from, _value);
    }

    function depositToken(Account storage a, address _token, address _from, uint _value) 
    internal noReentrance 
    {        
        require(ERC20(_token).transferFrom(_from, address(this), _value), "Token transfer not possible!");
        totalTokenBalances[_token] = totalTokenBalances[_token].add(_value);
        a.tokenBalances[_token] = a.tokenBalances[_token].add(_value);
        emit TokenDeposited(a.name, _token, _from, _value);
    }

    function sendETH(Account storage a, address payable _to, uint _value) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value, "Insufficient ETH balance!");
        require(_to != address(0), "Invalid recipient addess!");
        
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);

        _to.transfer(_value);
        
        emit ETHSent(a.name, _to, _value);
    }

    function transact(Account storage a, address _to, uint _value, bytes memory data) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value, "Insufficient ETH balance!");
        require(_to != address(0), "Invalid recipient addess!");
       
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);
        bool result = false;
        (result, ) = _to.call.value(_value)(data);
        require(result, "Transaction failed!");
        
        emit ETHSent(a.name, _to, _value);
    }

    function sendToken(Account storage a, address _token, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.tokenBalances[_token] >= _value, "Insufficient token balance!");
        require(_to != address(0), "Invalid recipient addess!");
        
        a.tokenBalances[_token] = a.tokenBalances[_token].sub(_value);
        totalTokenBalances[_token] = totalTokenBalances[_token].sub(_value);

        require(ERC20(_token).transfer(_to, _value), "Token transfer failed!");
        emit TokenSent(a.name, _token, _to, _value);
    }

    function transferETH(Account storage _from, Account storage _to, uint _value) 
    internal 
    {
        require(_from.balanceETH >= _value, "Insufficient ETH balance in account!");
        _from.balanceETH = _from.balanceETH.sub(_value);
        _to.balanceETH = _to.balanceETH.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    function transferToken(Account storage _from, Account storage _to, address _token, uint _value)
    internal
    {
        require(_from.tokenBalances[_token] >= _value, "Insufficient token balance in account!");
        _from.tokenBalances[_token] = _from.tokenBalances[_token].sub(_value);
        _to.tokenBalances[_token] = _to.tokenBalances[_token].add(_value);
        emit TokenTransferred(_from.name, _to.name, _token, _value);
    }

    function balanceETH(Account storage toAccount,  uint _value) internal {
        require(address(this).balance >= totalETH.add(_value), "No excess ETH available");
        depositETH(toAccount, address(this), _value);
    }

    function balanceToken(Account storage toAccount, address _token, uint _value) internal noReentrance {
        uint balance = ERC20(_token).balanceOf(address(this));
        require(balance >= totalTokenBalances[_token].add(_value), "No excess tokens available");

        toAccount.tokenBalances[_token] = toAccount.tokenBalances[_token].add(_value);
        emit TokenDeposited(toAccount.name, _token, address(this), _value);
    }
    
}
