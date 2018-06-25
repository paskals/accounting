pragma solidity^0.4.23;

import "../contracts/Accounting.sol";
import "../lib/ds-auth/src/auth.sol";

contract DepositBox is Accounting, DSAuth {

    mapping (address => Account) accounts;

    constructor () {}

    function () public payable {
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
        uint surplus = this.balance.sub(totalETH);
        balanceETH(base, surplus);
    }

    function redeemSurplusERC20(address token) public auth {
        uint realTokenBalance = ERC20(token).balanceOf(this);
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