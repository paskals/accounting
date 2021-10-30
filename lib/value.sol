// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0 <0.9.0;

abstract contract DSValue {
    bool has;
    bytes32 val;

    function peek() public view virtual returns (bytes32, bool);

    function read() public view virtual returns (bytes32);

    function poke(bytes32 wut) public virtual;

    function void() public virtual;
}
