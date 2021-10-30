// SPDX-License-Identifier: agpl-3.0
/// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity >=0.8.0 <0.9.0;

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}

abstract contract ERC20 is ERC20Events {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address guy) public view virtual returns (uint256);

    function allowance(address src, address guy)
        public
        view
        virtual
        returns (uint256);

    function approve(address guy, uint256 wad) public virtual returns (bool);

    function transfer(address dst, uint256 wad) public virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public virtual returns (bool);
}
