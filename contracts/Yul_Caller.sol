pragma solidity 0.8.7;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
interface IYul_Test {
    function balanceOf(address account, uint256 id) external view returns(uint256);
    function mint(address,uint256,uint256,bytes memory) external returns(bool);
    function mintBatch(address,uint256[] calldata,uint256[] calldata,bytes calldata) external;
    function uri(uint256) external view returns(string memory);
}   

contract Yul_Caller {
    address public yulContractAddress;
    constructor(){
        address b;
        assembly {
            mstore(0x0,0x336000557f68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f7b69)
            mstore(0x20,0x647d2e6a736020556137b760f11b6040556103778061003f6000396000f3fe60)
            mstore(0x40,0xc06080526000803560e01c90818062fdd58e1461018a578063731133e9146100)
            mstore(0x60,0xe55780631f7fdffa1461005e57630e89341c1461003e576020918152f35b6080)
            mstore(0x80,0x9061005c60206000526022602052602054604052604054606052565bf35b5090)
            mstore(0xa0,0x5061007161006c6101b0565b610370565b602490813591604435908360040182)
            mstore(0xc0,0x60040191813593833595610095878714610370565b8581106100bc5750505061)
            mstore(0xe0,0x00b294506100ac6101b0565b3361026a565b6100ba6101f9565b005b806100df)
            mstore(0x100,0x60019260051b858b818784010135920101356100da6101b0565b610227565b01)
            mstore(0x120,0x610095565b5050506100f361006c6101b0565b61010e6100fe6101e0565b6101)
            mstore(0x140,0x066101d2565b6100da6101b0565b6101366101196101e0565b6101216101d256)
            mstore(0x160,0x5b6101296101b0565b6101316101b0565b610239565b6101496101416101b056)
            mstore(0x180,0x5b503233141990565b610155576100ba6101f9565b61018561006c6064356024)
            mstore(0x1a0,0x8160040135910161016f6101e0565b6101776101d2565b61017f6101b0565b33)
            mstore(0x1c0,0x6102c6565b6100b2565b5060fd9150526100ba6101ab61019e6101d2565b6101)
            mstore(0x1e0,0xa66101b0565b610219565b6101ee565b602436106101cd576004359060016001)
            mstore(0x200,0x60a01b031982166101cd57565b600080fd5b604436106101cd5760243590565b)
            mstore(0x220,0x606436106101cd5760443590565b905060005260206000f35b50600160005260)
            mstore(0x240,0x206000f35b906080600052602052604052606060002090565b90610223916102)
            mstore(0x260,0x05565b5490565b9061023191610205565b908154019055565b90926000928352)
            mstore(0x280,0x6020527fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aac)
            mstore(0x2a0,0xaa2d0f62604083a4565b92947f4a39dc06d4c0dbc64b70af90fd698a233a518a)
            mstore(0x2c0,0xa5d07e595d983b8c0526c8f7fb92600095929660608460051b60406080515281)
            mstore(0x2e0,0x810160206080510152806020018094604060805101376080510101370160061b)
            mstore(0x300,0x608051a4565b9295949195939093600096323314196102e2575b505050505050)
            mstore(0x320,0x565b60809463f23a6e6160e01b86515260048651015260006024865101526044)
            mstore(0x340,0x8551015260648451015260a06084845101528161034b575b506001811061032a)
            mstore(0x360,0x575b8080806102da565b6004939450918160009360a460c49451015251928391)
            mstore(0x380,0x5af190388080610322565b8180965060a48451015260c4835101376004815185)
            mstore(0x3a0,0x60a401816000865af19338610318565b156101cd575600000000000000000000)
            b:= create(0,0x00, 0x3c0)
        }
        if(b == address(0)){
            console.log("Something went wrong.");
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

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public{
        IYul_Test(yulContractAddress).mintBatch(to, ids, amounts, data);
    }

    function uri() public view returns(string memory){
        return IYul_Test(yulContractAddress).uri(0);
    }

}

