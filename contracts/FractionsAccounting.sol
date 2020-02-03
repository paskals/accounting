/**
    @title: Fractions Accounting
    @author: Paskal S
 */
pragma solidity^0.5.0;

import "./SimpleAccounting.sol";
import "./Accounting.sol";

contract FractionsAccounting is Accounting, SimpleAccounting {

    struct FractionAccount {
        bytes32 name;
        uint balance;
        uint shares;
        uint lastCumulativeDeposits;
        uint lastWithdrawnBnum;
    }

    struct SharedAccount {
        uint totalShares;
        uint cumulativeDeposits;
        uint lastDepositBnum;
        bool finalized;
        SimpleAccount base;
        mapping (bytes32 => FractionAccount) subAccounts;
    }

    event SharesIssued(bytes32 indexed SharedAccount, bytes32 indexed SubAccount, uint Shares);

    function issueShares(SharedAccount storage a, bytes32 toSubAccount, uint _shares) internal {
        require(!a.finalized, "Can't issue shares after an account is finalized!");
        a.totalShares = a.totalShares.add(_shares);
        a.subAccounts[toSubAccount].shares = a.subAccounts[toSubAccount].shares.add(_shares);
        a.totalShares = a.totalShares.add(_shares);
        
        emit SharesIssued(a.base.name, toSubAccount, _shares);
    }

    function depositETH(SharedAccount storage a, address _from, uint _value) internal {
        //Deposits can be made before and after finalization
        depositETH(a.base, _from, _value);
        a.cumulativeDeposits = a.cumulativeDeposits.add(_value);
        a.lastDepositBnum = block.number;
    }

    function finalizeSharedAccount(SharedAccount storage a) internal {
        require(!a.finalized, "Already finalized!");
        a.finalized = true;
    }

    function updateBalance(SharedAccount storage a, bytes32 subAccount) internal {
        require(a.finalized, "Can't accurately update balance if not finalized.");
        uint newBalance = a.cumulativeDeposits.sub(a.subAccounts[subAccount].lastCumulativeDeposits);
        uint outstanding = newBalance.wmul(a.subAccounts[subAccount].shares).wdiv(a.totalShares);
        if (outstanding > 0) {
            a.subAccounts[subAccount].balance = a.subAccounts[subAccount].balance.add(outstanding);
            a.subAccounts[subAccount].lastCumulativeDeposits = a.totalShares;
        }
    }

    function balanceAvailable(SharedAccount storage a, bytes32 subAccount) internal view returns(bool){
        return a.lastDepositBnum > a.subAccounts[subAccount].lastWithdrawnBnum;
    }

    function transferETH(
        SimpleAccount storage _from,
        SharedAccount storage _to, 
        uint _value) 
    internal 
    {   
        transferETH(_from, _to.base, _value);
        _to.cumulativeDeposits = _to.cumulativeDeposits.add(_value);
        _to.lastDepositBnum = block.number;
    }

    function sendOutstandingETH(SharedAccount storage a, bytes32 _subAccount, address _to) 
    internal noReentrance 
    {
        require(balanceAvailable(a, _subAccount), "Insufficient ETH balance!");
        updateBalance(a, _subAccount);
        uint _value = a.subAccounts[_subAccount].balance;
        
        a.subAccounts[_subAccount].lastWithdrawnBnum = block.number;
        a.subAccounts[_subAccount].balance = 0;
        
        sendETH(a.base, _to, _value);
    }
}
