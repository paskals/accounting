// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../contracts/Accounting.sol";
import "../lib/auth.sol";

contract DepositBox is Accounting, DSAuth {
    using DSMath for uint256;

    mapping(address => Account) accounts;

    constructor() {}

    fallback() external payable {
        depositETH(accounts[msg.sender], msg.sender, msg.value);
    }

    function deposit() public payable {
        depositETH(accounts[msg.sender], msg.sender, msg.value);
    }

    function depositERC20(address token, uint256 value) public {
        depositToken(accounts[msg.sender], token, msg.sender, value);
    }

    function withdraw(uint256 value) public {
        sendETH(accounts[msg.sender], payable(msg.sender), value);
    }

    function withdrawERC20(address token, uint256 value) public {
        sendToken(accounts[msg.sender], token, msg.sender, value);
    }

    function ethBalance(address guy) public view returns (uint256 balance) {
        return accounts[guy].balanceETH;
    }

    function tokenBalance(address guy, address token)
        public
        view
        returns (uint256 balance)
    {
        return accounts[guy].tokenBalances[token];
    }

    function redeemSurplusETH() public auth {
        uint256 surplus = address(this).balance.sub(totalETH);
        balanceETH(base, surplus);
    }

    function redeemSurplusERC20(address token) public auth {
        uint256 realTokenBalance = ERC20(token).balanceOf(address(this));
        uint256 surplus = realTokenBalance.sub(totalTokenBalances[token]);
        balanceToken(base, token, surplus);
    }

    function withdrawBaseETH() public auth {
        sendETH(base, payable(msg.sender), base.balanceETH);
    }

    function withdrawBaseERC20(address token) public auth {
        sendToken(base, token, msg.sender, base.tokenBalances[token]);
    }
}
