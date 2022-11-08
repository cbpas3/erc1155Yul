pragma solidity 0.8.7;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
interface IYul_Test {
    function balanceOf(address account, uint256 id) external view returns(uint256);
    function mint(address,uint256,uint256,bytes memory) external returns(bool);
}   

contract Yul_Caller {
    address public yulContractAddress;
    constructor(){
        address b;
        assembly {
            mstore(0x0,0x3360005560d8806100116000396000f3fe6000803560e01c808062fdd58e1460)
            mstore(0x20,0x5e5763731133e9146020578152602090f35b5060643610605b57602e6089565b)
            mstore(0x40,0x6034609b565b906001600160a01b03198216605757604f92506044359160c856)
            mstore(0x60,0x5b605560a8565b005b8280fd5b80fd5b8260656089565b606b609b565b600160)
            mstore(0x80,0x0160a01b031981166057576020929160849160b4565b548152f35b6044361060)
            mstore(0xa0,0x965760243590565b600080fd5b6024361060965760043590565b506001600052)
            mstore(0xc0,0x60206000f35b906080600052602052604052606060002090565b9060d09160b4)
            mstore(0xe0,0x565b908154019055560000000000000000000000000000000000000000000000)
            b:= create(0,0x00, 0x100)
        }
        if(b == address(0)){
            console.log("fuck");
        } else{
            yulContractAddress = b;
        }

    }
    

    function balanceOf(address account, uint256 id) public view returns(uint256){
        return IYul_Test(yulContractAddress).balanceOf(account, id);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public returns(bool){
        return IYul_Test(yulContractAddress).mint(to,id,amount,data);
    }


}