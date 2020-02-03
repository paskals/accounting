pragma solidity >=0.5.0 <0.6.0;

import "../contracts/Accounting.sol";
import "../lib/auth.sol";

contract DepositBox is Accounting, DSAuth {

    mapping (address => Account) accounts;

    constructor () public {}

    function () external payable {
        depositETH(accounts[msg.sender], msg.sender, msg.value);
    }

    function deposit() public payable {
        depositETH(accounts[msg.sender], msg.sender, msg.value);
    }

    function depositERC20(address token, uint value) public {
        depositToken(accounts[msg.sender], token, msg.sender, value);
    }

    function withdraw(uint value) public {
        sendETH(accounts[msg.sender], msg.sender, value);
    }

    function withdrawERC20(address token, uint value) public {
        sendToken(accounts[msg.sender], token, msg.sender, value);
    }

    function ethBalance(address guy) public view returns(uint balance) {
        return accounts[guy].balanceETH;
    }

    function tokenBalance(address guy, address token) public view returns(uint balance) {
        return accounts[guy].tokenBalances[token];
    }

    function redeemSurplusETH() public auth {
        uint surplus = address(this).balance.sub(totalETH);
        balanceETH(base, surplus);
    }

    function redeemSurplusERC20(address token) public auth {
        uint realTokenBalance = ERC20(token).balanceOf(address(this));
        uint surplus = realTokenBalance.sub(totalTokenBalances[token]);
        balanceToken(base, token, surplus);
    }

    function withdrawBaseETH() public auth {
        sendETH(base, msg.sender, base.balanceETH);
    }

    function withdrawBaseERC20(address token) public auth {
        sendToken(base, token, msg.sender, base.tokenBalances[token]);
    }
}