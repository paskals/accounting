// SPDX-License-Identifier: agpl-3.0
/**
    @title: Fractions Accounting
    @author: Paskal S
 */
pragma solidity >=0.8.0 <0.9.0;

import "./SimpleAccounting.sol";
import "./Accounting.sol";

contract FractionsAccounting is SimpleAccounting, Accounting {
    using DSMath for uint256;

    uint256 public override(Accounting, SimpleAccounting) totalETH;

    struct FractionAccount {
        bytes32 name;
        uint256 balance;
        uint256 shares;
        uint256 lastCumulativeDeposits;
        uint256 lastWithdrawnBnum;
    }

    struct SharedAccount {
        uint256 totalShares;
        uint256 cumulativeDeposits;
        uint256 lastDepositBnum;
        bool finalized;
        SimpleAccount base;
        mapping(bytes32 => FractionAccount) subAccounts;
    }

    event SharesIssued(
        bytes32 indexed SharedAccount,
        bytes32 indexed SubAccount,
        uint256 Shares
    );

    function issueShares(
        SharedAccount storage a,
        bytes32 toSubAccount,
        uint256 _shares
    ) internal {
        require(
            !a.finalized,
            "Can't issue shares after an account is finalized!"
        );
        a.totalShares = a.totalShares.add(_shares);
        a.subAccounts[toSubAccount].shares = a
            .subAccounts[toSubAccount]
            .shares
            .add(_shares);
        a.totalShares = a.totalShares.add(_shares);

        emit SharesIssued(a.base.name, toSubAccount, _shares);
    }

    function depositETH(
        SharedAccount storage a,
        address _from,
        uint256 _value
    ) internal {
        //Deposits can be made before and after finalization
        depositETH(a.base, _from, _value);
        a.cumulativeDeposits = a.cumulativeDeposits.add(_value);
        a.lastDepositBnum = block.number;
    }

    function finalizeSharedAccount(SharedAccount storage a) internal {
        require(!a.finalized, "Already finalized!");
        a.finalized = true;
    }

    function updateBalance(SharedAccount storage a, bytes32 subAccount)
        internal
    {
        require(
            a.finalized,
            "Can't accurately update balance if not finalized."
        );
        uint256 newBalance = a.cumulativeDeposits.sub(
            a.subAccounts[subAccount].lastCumulativeDeposits
        );
        uint256 outstanding = newBalance
            .wmul(a.subAccounts[subAccount].shares)
            .wdiv(a.totalShares);
        if (outstanding > 0) {
            a.subAccounts[subAccount].balance = a
                .subAccounts[subAccount]
                .balance
                .add(outstanding);
            a.subAccounts[subAccount].lastCumulativeDeposits = a.totalShares;
        }
    }

    function balanceAvailable(SharedAccount storage a, bytes32 subAccount)
        internal
        view
        returns (bool)
    {
        return a.lastDepositBnum > a.subAccounts[subAccount].lastWithdrawnBnum;
    }

    function transferETH(
        SimpleAccount storage _from,
        SharedAccount storage _to,
        uint256 _value
    ) internal {
        transferETH(_from, _to.base, _value);
        _to.cumulativeDeposits = _to.cumulativeDeposits.add(_value);
        _to.lastDepositBnum = block.number;
    }

    function sendOutstandingETH(
        SharedAccount storage a,
        bytes32 _subAccount,
        address payable _to
    ) internal noReentrance {
        require(balanceAvailable(a, _subAccount), "Insufficient ETH balance!");
        updateBalance(a, _subAccount);
        uint256 _value = a.subAccounts[_subAccount].balance;

        a.subAccounts[_subAccount].lastWithdrawnBnum = block.number;
        a.subAccounts[_subAccount].balance = 0;

        SimpleAccounting.sendETH(a.base, _to, _value);
    }

    function baseETHBalance()
        public
        view
        override(Accounting, SimpleAccounting)
        returns (uint256)
    {
        return base.balanceETH;
    }
}
