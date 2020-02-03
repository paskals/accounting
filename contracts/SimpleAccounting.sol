/**
    @title: Simple Accounting
    @author: Paskal S
 */
pragma solidity^0.5.0;

import "../lib/math-lib.sol";
import "../lib/erc20.sol";

/**
    a simple base contract with accounting functionality for ETH only accounts
 */
contract SimpleAccounting {

    using DSMath for uint;

    bool internal _in;
    
    modifier noReentrance() {
        require(!_in, "Reentrance not allowed!");
        _in = true;
        _;
        _in = false;
    }
    
    //We need to keep track of the total ETH ourselves as this.balance is unreliable
    uint public totalETH;

    //A simple account has a balance and a name
    struct SimpleAccount {
        bytes32 name;
        uint balance;        
    }

    //There's always a base account
    SimpleAccount base = SimpleAccount({
        name: "Base",
        balance: 0        
    });

    event ETHDeposited(bytes32 indexed account, address indexed from, uint value);
    event ETHSent(bytes32 indexed account, address indexed to, uint value);
    event ETHTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, uint value);

    function baseETHBalance() public view returns(uint) {
        return base.balance;
    }

    function depositETH(SimpleAccount storage a, address _from, uint _value) internal {
        a.balance = a.balance.add(_value);
        totalETH = totalETH.add(_value);
        emit ETHDeposited(a.name, _from, _value); 
    }

    function sendETH(SimpleAccount storage a, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.balance >= _value, "Insufficient ETH balance!");
        require(_to != address(0), "Invalid recipient addess!");
        
        a.balance = a.balance.sub(_value);
        totalETH = totalETH.sub(_value);

        _to.transfer(_value);
        
        emit ETHSent(a.name, _to, _value);
    }

    function transact(SimpleAccount storage a, address _to, uint _value, bytes data) 
    internal noReentrance 
    {
        require(a.balance >= _value, "Insufficient ETH balance!");
        require(_to != address(0), "Invalid recipient addess!");
        
        a.balance = a.balance.sub(_value);
        totalETH = totalETH.sub(_value);

        require(_to.call.value(_value)(data), "Transaction failed!");
        
        emit ETHSent(a.name, _to, _value);
    }

    function transferETH(SimpleAccount storage _from, SimpleAccount storage _to, uint _value) 
    internal 
    {
        require(_from.balance >= _value, "Insufficient ETH balance in account!");
        _from.balance = _from.balance.sub(_value);
        _to.balance = _to.balance.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    /**
        @notice we can balance surpluses to an account - e.g. if this.balance increases without our accounting, we can balance the surplus to an account
     */
    function balance(SimpleAccount storage toAccount,  uint _value) internal {
        require(address(this).balance >= totalETH.add(_value), "No excess ETH available");
        depositETH(toAccount, 0x0, _value);
    }

}