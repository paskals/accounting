// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../contracts/AllowanceAccounting.sol";
import "../lib/auth.sol";

contract Payroll is AllowanceAccounting, DSAuth {
    using DSMath for uint256;

    mapping(address => LimitedAccount) accounts;

    constructor() {
        //set Dai address
    }

    function deposit(address _for) public payable {
        depositETH(accounts[_for], msg.sender, msg.value);
    }

    function depositStablecoin(address _for, uint256 value) public {
        depositDai(accounts[_for], msg.sender, value);
    }

    function withdrawAllowanceETH() public {
        sendETHAllowance(accounts[msg.sender], payable(msg.sender));
    }

    function withdrawAllowanceDai() public {
        sendDaiAllowance(accounts[msg.sender], msg.sender);
    }

    function setAllowance(address guy, uint256 daiPerSecond) public auth {
        accounts[guy].allowance = daiPerSecond;
    }
}
