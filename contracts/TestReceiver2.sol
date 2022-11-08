pragma solidity 0.8.7;

contract TestReceiver2 {
    function giveNumber(uint256 arg1, uint256 arg2, uint256 arg3) public pure returns(uint256){
        uint256 sum = arg1 + arg2 + arg3;
        return sum;
    }
}