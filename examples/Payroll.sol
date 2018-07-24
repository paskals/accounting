pragma solidity^0.4.23;

import "../contracts/AllowanceAccounting.sol";
import "../lib/auth.sol";

contract Payroll is AllowanceAccounting, DSAuth {

    mapping (address => LimitedAccount) accounts;

    constructor () {
        //set Dai address
    }

    function deposit(address _for) public payable {
        depositETH(accounts[_for], msg.sender, msg.value);
    }

    function depositStablecoin(address _for, uint value) public {
        depositDai(accounts[_for], msg.sender, value);
    }

    function withdrawAllowanceETH() public {
        sendETHAllowance(accounts[msg.sender], msg.sender);
    }

    function withdrawAllowanceDai() public {
        sendDaiAllowance(accounts[msg.sender], msg.sender);
    }

    function setAllowance(address guy, uint daiPerSecond) public auth {
        accounts[guy].allowance = daiPerSecond;
    }

}