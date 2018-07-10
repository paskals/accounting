pragma solidity^0.4.23;

import "../contracts/Accounting.sol";
import "../lib/auth.sol";

contract RefundableCampaign is SubAccounting, DSAuth {

    bool public failed;
    uint public deadline;
    uint public totalContributed;
    uint public goal = 1 ether;
    SuperAccount contributions;

    constructor () {
        deadline = now + 5 minutes;
    }

    function contribute() public payable {
        require(now <= deadline);
        totalContributed += msg.value;
        depositETH(contributions, bytes32(msg.sender), msg.sender, msg.value);
    }

    function myContribution(address guy) public view returns(uint) {
        return contributions.subAccounts[bytes32(guy)].balanceETH;
    }

    function finalize() public auth {
        require(now > deadline);
        if (totalContributed < goal) {
            failed = true;
        } else {
            drainETH(contributions, base);
        }
    }

    function refund() public {
        require(now > deadline);
        if (totalContributed < goal) {
            sendETH(
                contributions, bytes32(msg.sender), msg.sender, 
                contributions.subAccounts[bytes32(msg.sender)].balanceETH
                );
        }
    }

    function withdrawBaseETH() public auth {
        sendETH(base, msg.sender, base.balanceETH);
    }

}