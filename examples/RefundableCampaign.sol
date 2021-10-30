// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../contracts/SubAccounting.sol";
import "../lib/auth.sol";

contract RefundableCampaign is SubAccounting, DSAuth {
    using DSMath for uint256;

    bool public failed;
    uint256 public deadline;
    uint256 public totalContributed;
    uint256 public goal = 1 ether;
    SuperAccount contributions;

    constructor() {
        deadline = block.timestamp + 5 minutes;
    }

    function contribute() public payable {
        require(block.timestamp <= deadline);
        totalContributed += msg.value;
        depositETH(contributions, bytes20(msg.sender), msg.sender, msg.value);
    }

    function myContribution(address guy) public view returns (uint256) {
        return contributions.subAccounts[bytes20(guy)].balanceETH;
    }

    function finalize() public auth {
        require(block.timestamp > deadline);
        if (totalContributed < goal) {
            failed = true;
        } else {
            drainETH(contributions, base);
        }
    }

    function refund() public {
        require(block.timestamp > deadline);
        if (totalContributed < goal) {
            SubAccounting.sendETH(
                contributions,
                bytes20(msg.sender),
                payable(msg.sender),
                contributions.subAccounts[bytes20(msg.sender)].balanceETH
            );
        }
    }

    function withdrawBaseETH() public auth {
        Accounting.sendETH(base, payable(msg.sender), base.balanceETH);
    }
}
