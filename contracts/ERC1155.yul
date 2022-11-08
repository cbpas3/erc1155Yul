object "Yul_Test" {
    code{
        // Store the creator in slot zero.
        sstore(0, caller())
        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Set free memory pointer
            mstore(fmpPos(), 0xc0)
            switch selector()
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                mstore(0,0x00fd)
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            case 0x731133e9 /* "mint(address,uint25,uint25,bytes)" */ {
                mstore(0,0x7311)
                revertIfZeroAddress(decodeAsAddress(0))
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                emitTransferSingle(decodeAsAddress(0), 0, decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                if isContract(decodeAsAddress(0)){
                    let dLocation2 := add(4,mul(0x20,3))
                    let dLengthLocation := add(4,calldataload(dLocation2))
                    let dLength := calldataload(dLengthLocation)
                    let dLocationStart := add(dLengthLocation,32)
                    require(doSafeTransferAcceptanceCheck(caller(),0x00,decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2),dLocationStart, dLength))
                }
                returnTrue()
            }

            case 0x9550a975 /* "doSafeTransferAcceptanceCheckTest(address,uint25,uint25,bytes)" */{
                mstore(0,0x9550)
                let dLocation2 := add(4,mul(0x20,3))
                let dLengthLocation := add(4,calldataload(dLocation2))
                let dLength := calldataload(dLengthLocation)
                let res := doSafeTransferAcceptanceCheck(caller(),caller(),decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2),dLocation2, dLength)
                require(res)
            }



            default {
                mstore(0x00,selector())
                return(0,0x20)
            }

            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsBytesStringToMemory(offset) {
                // Adds the Bytes[]/String to memory
                
                // This is the position of the number pointing to where
                // the data is for array  based from the start of the arguments
                // This number does not take the function sig into account
                let pos := add(4, mul(offset, 0x20))

                // The data is located 
                let posOfDataLength := add(4,calldataload(pos))
                let posOfDataStart := add(posOfDataLength,0x20)
                // Length of the array
                let numberOfElements := calldataload(add(4,calldataload(pos)))
                
                switch gt(numberOfElements,16)
                case 0{
                    mstore(fmp(), calldataload(posOfDataStart))
                    updateFmp(0x20)
                } 
                default {
                    let numberOfLoops:= add(div(numberOfElements,16),1)
                    for { let i := 0 } lt(i, numberOfLoops) { i := add(i, 1) } {     
                        let wordCount := mul(i,0x20)
                        // Load data to memory
                        mstore(fmp(), calldataload(add(posOfDataStart, wordCount)))
                        updateFmp(0x20)
                    }
                }



            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

        /* ---------- calldata encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            function returnTrue() {
                returnUint(1)
            }
        /* ---------- Memory -----------*/
            function fmpPos() -> p { p:= 0x80 }
            function fmp() -> p { 
                p:= mload(fmpPos())
            }
            function updateFmp(numberOfBytes) {
                mstore(fmpPos(), add(fmp(), numberOfBytes))
                
                // let pos := fmp()
                // switch pos
                // case 0xa0 {
                //     mstore(fmpPos(),add(0xc0,numberOfBytes))
                // }
                // default {
                //     mstore(fmpPos(), add(fmp(), numberOfBytes))
                // }
            }

        /* ---------- Storage Layout ----------*/

            function ownerPos() -> p { p := 0x00 }
            function uriPos() -> p { p := 0x20 }
            function accountToStorageOffset(account, token_id) -> offset {
                mstore(0x00,0x80)
                mstore(0x20,token_id)
                mstore(0x40,account)
                offset := keccak256(0,0x60)
            }
            function allowanceStorageOffset(account, operator) -> offset {
                mstore(0x00,0xa0)
                mstore(0x20,account)
                mstore(0x40,operator)
                offset := keccak256(0, 0x60)
            }

        /* ---------- Storage Access ---------- */

            function balanceOf(account, token_id) -> bal {
                bal := sload(accountToStorageOffset(account, token_id))
            }

            function owner() -> o {
                o := sload(ownerPos())
            }

            function mint(account,token_id,amount) {
                let slot:= accountToStorageOffset(account, token_id)
                let bal := sload(slot)
                bal := add(bal, amount)
                sstore(slot, bal)
            } 

        /* ---------- events ---------- */
            function emitTransferSingle(operator, from, to, id, amount) {
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0, id)
                mstore(0x20, amount)
                log4(0, 0x40, signatureHash, operator, from, to)
            }



        /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function doSafeTransferAcceptanceCheck(operator,from,to,id,amount,dataLocation, dataLength) -> success {
                success:= 0
                if isContract(to) {
                    // load the arguments
                    // function signature `onERC1155Received(address,address,uint256,uint256,bytes)`
                    mstore(fmp(),0xf23a6e6100000000000000000000000000000000000000000000000000000000) 
                    mstore(add(fmp(),4), operator) // caller()
                    mstore(add(fmp(),36), from) // caller()
                    // mstore(add(fmp(),68), to) 
                    mstore(add(fmp(),68), id)
                    mstore(add(fmp(),100), amount)
                    mstore(add(fmp(),132), 160)
                    if gt(dataLength, 0){
                        mstore(add(fmp(),164),dataLength)
                        calldatacopy(add(fmp(),196),dataLocation,dataLength)
                        success:= call(gas(),to, 0, fmp(),  add(164,dataLength), fmp(), 4)
                    }
                    if lt(dataLength, 1){
                        mstore(add(fmp(),164),dataLength)
                        success:= call(gas(),to, 0, fmp(),  196, fmp(), 4)
                    }
                    
                }
            }

            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }
            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }
            function revertIfZeroAddress(addr) {
                require(addr)
            }

            function isContract(addr) -> ic {
                ic := not(eq(caller(),origin()))
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            function callDataFormatter(hash, arg1,arg2,arg3,arg4,arg5){
                // load free memory pointer
                // 
            }

            function callOtherContract(){
                // input should be 
                // 0x 
                // function signature: f23a6e61
                // argument 1: 32 bytes
                // argument 2: 32 bytes
                // argument 3: 32 bytes
                // argument 4: 32 bytes


            }
        }


    }
}