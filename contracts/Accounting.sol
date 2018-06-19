/**
    @title: Accounting
    @dev: various base contracts with accounting functionality
    @author: Paskal S
 */

pragma solidity^0.4.21;

import "./math-lib.sol";

interface ERC20 {
    function balanceOf(address src) external view returns (uint);
    function totalSupply() external view returns (uint);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface DSValue {
    function peek() external constant returns (bytes32, bool);
    function read() external constant returns (bytes32);
}


/**
    a simple base contract with accounting functionality for ETH only accounts
 */
contract SimpleAccounting {

    using DSMath for uint;

    bool internal _in;
    
    modifier noReentrance() {
        require(!_in);
        _in = true;
        _;
        _in = false;
    }
    
    //We need to keep track of the total ETH ourselves as this.balance is unreliable
    uint public totalETH;

    //A simple account has a balance and a name
    struct Account {
        bytes32 name;
        uint balance;        
    }

    //There's always a base account
    Account base = Account({
        name: "Base",
        balance: 0        
    });

    event ETHDeposited(bytes32 indexed account, address indexed from, uint value);
    event ETHSent(bytes32 indexed account, address indexed to, uint value);
    event ETHTransferred(bytes32 indexed fromAccount, bytes32 indexed toAccount, uint value);

    function baseETHBalance() public constant returns(uint) {
        return base.balance;
    }

    function depositETH(Account storage a, address _from, uint _value) internal {
        a.balance = a.balance.add(_value);
        totalETH = totalETH.add(_value);
        emit ETHDeposited(a.name, _from, _value); 
    }

    function sendETH(Account storage a, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.balance >= _value);
        require(_to != address(0));
        
        a.balance = a.balance.sub(_value);
        totalETH = totalETH.sub(_value);

        _to.transfer(_value);
        
        emit ETHSent(a.name, _to, _value);
    }

    function transact(Account storage a, address _to, uint _value, bytes data) 
    internal noReentrance 
    {
        require(a.balance >= _value);
        require(_to != address(0));
        
        a.balance = a.balance.sub(_value);
        totalETH = totalETH.sub(_value);

        require(_to.call.value(_value)(data));
        
        emit ETHSent(a.name, _to, _value);
    }

    function transferETH(Account storage _from, Account storage _to, uint _value) 
    internal 
    {
        require(_from.balance >= _value);
        _from.balance = _from.balance.sub(_value);
        _to.balance = _to.balance.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    /**
        @notice we can balance surpluses to an account - e.g. if this.balance increases without our accounting, we can balance the surplus to an account
     */
    function balance(Account storage toAccount,  uint _value) internal {
        require(address(this).balance >= totalETH.add(_value));
        depositETH(toAccount, 0x0, _value);
    }

}

/**
 a base contract with accounting functionality for ETH and ERC20 tokens
 */
contract Accounting {

    using DSMath for uint;

    bool internal _in;
    
    modifier noReentrance() {
        require(!_in);
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

    function baseETHBalance() public constant returns(uint) {
        return base.balanceETH;
    }

    function baseTokenBalance(address token) public constant returns(uint) {
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
        require(ERC20(_token).transferFrom(_from, address(this), _value));
        totalTokenBalances[_token] = totalTokenBalances[_token].add(_value);
        a.tokenBalances[_token] = a.tokenBalances[_token].add(_value);
        emit TokenDeposited(a.name, _token, _from, _value);
    }

    function sendETH(Account storage a, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value);
        require(_to != address(0));
        
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);

        _to.transfer(_value);
        
        emit ETHSent(a.name, _to, _value);
    }

    function transact(Account storage a, address _to, uint _value, bytes data) 
    internal noReentrance 
    {
        require(a.balanceETH >= _value);
        require(_to != address(0));
        
        a.balanceETH = a.balanceETH.sub(_value);
        totalETH = totalETH.sub(_value);

        require(_to.call.value(_value)(data));
        
        emit ETHSent(a.name, _to, _value);
    }

    function sendToken(Account storage a, address _token, address _to, uint _value) 
    internal noReentrance 
    {
        require(a.tokenBalances[_token] >= _value);
        require(_to != address(0));
        
        a.tokenBalances[_token] = a.tokenBalances[_token].sub(_value);
        totalTokenBalances[_token] = totalTokenBalances[_token].sub(_value);

        require(ERC20(_token).transfer(_to, _value));
        emit TokenSent(a.name, _token, _to, _value);
    }

    function transferETH(Account storage _from, Account storage _to, uint _value) 
    internal 
    {
        require(_from.balanceETH >= _value);
        _from.balanceETH = _from.balanceETH.sub(_value);
        _to.balanceETH = _to.balanceETH.add(_value);
        emit ETHTransferred(_from.name, _to.name, _value);
    }

    function transferToken(Account storage _from, Account storage _to, address _token, uint _value)
    internal
    {
        require(_from.tokenBalances[_token] >= _value);
        _from.tokenBalances[_token] = _from.tokenBalances[_token].sub(_value);
        _to.tokenBalances[_token] = _to.tokenBalances[_token].add(_value);
        emit TokenTransferred(_from.name, _to.name, _token, _value);
    }

    function balanceETH(Account storage toAccount,  uint _value) internal {
        require(address(this).balance >= totalETH.add(_value));
        depositETH(toAccount, address(this), _value);
    }

    function balanceToken(Account storage toAccount, address _token, uint _value) internal noReentrance {
        uint balance = ERC20(_token).balanceOf(this);
        require(balance >= totalTokenBalances[_token].add(_value));

        toAccount.tokenBalances[_token] = toAccount.tokenBalances[_token].add(_value);
        emit TokenDeposited(toAccount.name, _token, address(this), _value);
    }
    
}

/**
    a base contract with accounting functionality for accounts with a set allowance of ETH or Dai. The allowance is set as Dai/s and when withdrawing allowance in ETH, the price of ETH/Dai is first checked
 */
contract AllowanceAccounting is Accounting {
    
    ///Dai price feed
    DSValue priceFeed = DSValue(0x729D19f657BD0614b4985Cf1D82531c67569197B);// main net
    ///Dai ERC20 token
    ERC20 stableCoin = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);// main net


    struct LimitedAccount {
        Account base;
        uint allowance;
        uint lastWithdrawn;
    }

    function depositETH(LimitedAccount storage a, address _from, uint _value) internal {
        
        depositETH(a.base, _from, _value);
    }

    function depositDai(LimitedAccount storage a, address _from, uint _value) internal {
        
        depositToken(a.base, stableCoin, _from, _value);
    }

    function sendETHAllowance(LimitedAccount storage a, address _to) internal {
        require(a.base.balanceETH > 0);
        uint amount;
        
        uint price = uint256(priceFeed.read());
        uint due = a.allowance.mul(now.sub(a.lastWithdrawn));
        amount = due.wdiv(price);
        
        if (amount > a.base.balanceETH) {
            amount = a.base.balanceETH;
        }

        a.lastWithdrawn = now;
        sendETH(a.base, _to, amount);
    }

    function transactETHAllowance(LimitedAccount storage a, address _to, bytes data) 
    internal noReentrance
    {
        require(a.base.balanceETH > 0);
        uint amount;
        
        uint price = uint256(priceFeed.read());
        uint due = a.allowance.mul(now.sub(a.lastWithdrawn));
        amount = due.wdiv(price);
        
        if (amount > a.base.balanceETH) {
            amount = a.base.balanceETH;
        }

        a.lastWithdrawn = now;
        transact(a.base, _to, amount, data);
    }

    function sendDaiAllowance(LimitedAccount storage a, address _to) 
    internal 
    {
        require(a.base.tokenBalances[stableCoin] > 0);
        
        uint amount;

        amount = a.allowance.mul(now.sub(a.lastWithdrawn));
        
        if(amount > a.base.tokenBalances[stableCoin]) {
            amount == a.base.tokenBalances[stableCoin];
        }

        a.lastWithdrawn = now;
        
        sendToken(a.base, stableCoin, _to, amount);
    }

}

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