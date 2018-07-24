/**
    @title: Sub Accounting
    @author: Paskal S
 */
pragma solidity^0.4.24;

import "./Accounting.sol";

/**
    a base contract with accounting functionality for ETH and ERC20 tokens. It implements super accounts which can contain numerous sub accounts. The super account can be drained (using all of the sub balances together).
 */
contract SubAccounting is Accounting {
    
    struct SubAccount {
        uint balanceETH;
        mapping (address => uint) tokenBalances;
    }

    struct SuperAccount {
        Account base;
        mapping (bytes32 => SubAccount) subAccounts;
    }

    function depositETH(SuperAccount storage super, bytes32 _subKey, address _from, uint _value) internal {
        depositETH(super.base, _from, _value);
        super.subAccounts[_subKey].balanceETH = super.subAccounts[_subKey].balanceETH.add(_value);
    }

    function depositToken(SuperAccount storage super, bytes32 _subKey, address _token, address _from, uint _value) 
    internal  
    {        
        depositToken(super.base, _token, _from, _value);
        super.subAccounts[_subKey].tokenBalances[_token] = super.subAccounts[_subKey].tokenBalances[_token].add(_value);
        // emit TokenDeposited(a.name, _token, _from, _value);
    }

    ///Transfer from one sub account to another within two separate super accounts
    function transferETH(
        SuperAccount storage _from, 
        bytes32 _fromKey,
        SuperAccount storage _to, 
        bytes32 _toKey,
        uint _value) 
    internal 
    {   
        require(_from.subAccounts[_fromKey].balanceETH >= _value);
        transferETH(_from.base, _to.base, _value);        
        _from.subAccounts[_fromKey].balanceETH = _from.subAccounts[_fromKey].balanceETH.sub(_value);
        _to.subAccounts[_toKey].balanceETH = _to.subAccounts[_toKey].balanceETH.add(_value);
    }

    ///Transfer from one sub account to another within the same super account
    function transferETH(
        SuperAccount storage _super, 
        bytes32 _fromKey,
        bytes32 _toKey,
        uint _value) 
    internal 
    {   
        require(_super.subAccounts[_fromKey].balanceETH >= _value);
        _super.subAccounts[_fromKey].balanceETH = _super.subAccounts[_fromKey].balanceETH.sub(_value);
        _super.subAccounts[_toKey].balanceETH = _super.subAccounts[_toKey].balanceETH.add(_value);
    }

    ///Transfer from one sub account to a normal account
    function transferETH(
        SuperAccount storage _from, 
        bytes32 _fromKey,
        Account storage _to,
        uint _value) 
    internal 
    {   
        require(_from.subAccounts[_fromKey].balanceETH >= _value);
        transferETH(_from.base, _to, _value);
        _from.subAccounts[_fromKey].balanceETH = _from.subAccounts[_fromKey].balanceETH.sub(_value);
    }

    ///Transfer from a normal account to a sub account
    function transferETH(
        Account storage _from,
        SuperAccount storage _to, 
        bytes32 _toKey,
        uint _value) 
    internal 
    {   
        transferETH(_from, _to.base, _value);
        _to.subAccounts[_toKey].balanceETH = _to.subAccounts[_toKey].balanceETH.add(_value);
    }

    function sendETH(SuperAccount storage a, bytes32 _fromKey, address _to, uint _value) 
    internal  
    {
        require(a.subAccounts[_fromKey].balanceETH >= _value);
        a.subAccounts[_fromKey].balanceETH = a.subAccounts[_fromKey].balanceETH.sub(_value);
        sendETH(a.base, _to, _value);
    }

    ///Transfer tokens from one sub account to another within two separate super accounts
    function transferToken(
        SuperAccount storage _from, 
        bytes32 _fromKey,
        SuperAccount storage _to, 
        bytes32 _toKey,
        address _token,
        uint _value) 
    internal  
    {
        require(_from.subAccounts[_fromKey].tokenBalances[_token] >= _value);
        transferToken(_from.base, _to.base, _token, _value);        
        _from.subAccounts[_fromKey].tokenBalances[_token] = _from.subAccounts[_fromKey].tokenBalances[_token].sub(_value);
        _to.subAccounts[_toKey].tokenBalances[_token] = _to.subAccounts[_toKey].tokenBalances[_token].add(_value);
    }

    ///Transfer tokens from one sub account to another within the same super account
    function transferToken(
        SuperAccount storage _super, 
        bytes32 _fromKey,
        bytes32 _toKey,
        address _token, 
        uint _value) 
    internal 
    {   
        require(_super.subAccounts[_fromKey].tokenBalances[_token] >= _value);
        _super.subAccounts[_fromKey].tokenBalances[_token] = _super.subAccounts[_fromKey].tokenBalances[_token].sub(_value);
        _super.subAccounts[_toKey].tokenBalances[_token] = _super.subAccounts[_toKey].tokenBalances[_token].add(_value);
    }

    ///Transfer tokens from one sub account to a normal account
    function transferToken(
        SuperAccount storage _from, 
        bytes32 _fromKey,
        Account storage _to,
        address _token,
        uint _value) 
    internal 
    {   
        require(_from.subAccounts[_fromKey].tokenBalances[_token] >= _value);
        transferToken(_from.base, _to, _token, _value);
        _from.subAccounts[_fromKey].tokenBalances[_token] = _from.subAccounts[_fromKey].tokenBalances[_token].sub(_value);
    }

    ///Transfer tokens from a normal account to a sub account
    function transferToken(
        Account storage _from,
        SuperAccount storage _to, 
        bytes32 _toKey,
        address _token,
        uint _value) 
    internal 
    {
        transferToken(_from, _to.base, _token, _value);
        _to.subAccounts[_toKey].tokenBalances[_token] = _to.subAccounts[_toKey].tokenBalances[_token].add(_value);
    }

    function sendToken(SuperAccount storage a, bytes32 _fromKey, address _to, address _token, uint _value) 
    internal 
    {
        require(a.subAccounts[_fromKey].tokenBalances[_token] >= _value);
        a.subAccounts[_fromKey].tokenBalances[_token] = a.subAccounts[_fromKey].tokenBalances[_token].sub(_value);
        sendToken(a.base, _to, _token, _value);
    }
        
    ///A super account can be drained (although the sub-account balances can't be erased)
    function drainETH(SuperAccount storage _from, Account storage _to) internal {
        transferETH(_from.base, _to, _from.base.balanceETH);
    }

    function drainToken(SuperAccount storage _from, Account storage _to, address _token) internal {
        transferToken(_from.base, _to, _token, _from.base.tokenBalances[_token]);
    }

}
