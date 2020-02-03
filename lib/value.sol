pragma solidity>=0.4.18;

contract DSValue{
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool);
    function read() public view returns (bytes32);
    function poke(bytes32 wut) public;
    function void() public;
}
