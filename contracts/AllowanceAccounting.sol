/**
    @title: Allowance Accounting
    @author: Paskal S
 */
pragma solidity >=0.5.0 <0.6.0;

import "./Accounting.sol";
import "../lib/value.sol";

/**
    a base contract with accounting functionality for accounts with a set allowance of ETH or Dai. The allowance is set as Dai/s and when withdrawing allowance in ETH, the price of ETH/Dai is first checked
 */
contract AllowanceAccounting is Accounting {
    
    ///Dai price feed (possibly not up to date)
    DSValue priceFeed = DSValue(0x729D19f657BD0614b4985Cf1D82531c67569197B);// main net
    ///Dai ERC20 token (old SAI version)
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
        
        depositToken(a.base, address(stableCoin), _from, _value);
    }

    function sendETHAllowance(LimitedAccount storage a, address payable _to) internal {
        require(a.base.balanceETH > 0, "Insufficient ETH balance!");
        uint amount;
        
        uint price = uint256(priceFeed.read());
        uint due = a.allowance.mul(block.timestamp.sub(a.lastWithdrawn));
        amount = due.wdiv(price);
        
        if (amount > a.base.balanceETH) {
            amount = a.base.balanceETH;
        }

        a.lastWithdrawn = block.timestamp;
        sendETH(a.base, _to, amount);
    }

    function transactETHAllowance(LimitedAccount storage a, address _to, bytes memory data) 
    internal noReentrance
    {
        require(a.base.balanceETH > 0, "Insufficient ETH balance!");
        uint amount;
        
        uint price = uint256(priceFeed.read());
        uint due = a.allowance.mul(block.timestamp.sub(a.lastWithdrawn));
        amount = due.wdiv(price);
        
        if (amount > a.base.balanceETH) {
            amount = a.base.balanceETH;
        }

        a.lastWithdrawn = block.timestamp;
        transact(a.base, _to, amount, data);
    }

    function sendDaiAllowance(LimitedAccount storage a, address _to) 
    internal 
    {
        require(a.base.tokenBalances[address(stableCoin)] > 0, "Insufficient Dai balance!");
        
        uint amount;

        amount = a.allowance.mul(block.timestamp.sub(a.lastWithdrawn));
        
        if(amount > a.base.tokenBalances[address(stableCoin)]) {
            amount == a.base.tokenBalances[address(stableCoin)];
        }

        a.lastWithdrawn = block.timestamp;
        
        sendToken(a.base, address(stableCoin), _to, amount);
    }

}