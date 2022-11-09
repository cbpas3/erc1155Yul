object "Yul_Test" {
    code{
        // Store the creator in slot zero.
        sstore(0, caller())

        // Store the URI "https://token-cdn-domain/{id}.json"
        sstore(0x20, 0x68747470733A2F2F746F6B656E2D63646E2D646F6D61696E2F7B69647D2E6A73)
        sstore(0x40, 0x6F6E000000000000000000000000000000000000000000000000000000000000)
        
        
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
                revertIfZeroAddress(decodeAsAddress(0))
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                emitTransferSingle(decodeAsAddress(0), 0, decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                if isContract(decodeAsAddress(0)){
                    let data_length_offset := calldataload(0x64)
                    require(doSafeTransferAcceptanceCheck(caller(),0x00,decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2),data_length_offset))
    
                }
                returnTrue()
            }

            case 0x1f7fdffa /* "mintBatch(address,uint256[],uint256[],bytes)" */ {
                
                // ids
                let id_length_offset := calldataload(0x24)
                let id_length_location := add(4, id_length_offset)
                let id_length := calldataload(id_length_location)
                let id_first_elem_location := add(id_length_location, 0x20)

                // amounts
                let amount_length_offset := calldataload(0x44)   
                let amount_length_location := add(4, amount_length_offset)
                let amount_length := calldataload(amount_length_location)
                let amount_first_elem_location := add(amount_length_location, 0x20)
                revertIfZeroAddress(decodeAsAddress(0))
                require(eq(id_length,amount_length))

                // bytes
                let data_length_offset := calldataload(0x64)

                for { let i := 0} lt(i, id_length) { i := add(i, 1) } { 
                    mint(decodeAsAddress(0),calldataload(add(mul(i,0x20), id_first_elem_location)),calldataload(add(mul(i,0x20), amount_first_elem_location)))
                }
                emitTransferBatch(caller(), 0x00, decodeAsAddress(0), id_length_offset,amount_length_offset,id_length_location,amount_length_location,id_length,amount_length)
                require(doSafeBatchTransferAcceptanceCheck(caller(),0x00,decodeAsAddress(0),id_length_offset,amount_length_offset,data_length_offset))
                returnTrue()
            }

            case 0x0e89341c /* "uri(uint256)" */ {
                loadUriToMemory()
                return(0x00, 0x80)
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

            function loadUriToMemory(){
                mstore(0x00, 0x0000000000000000000000000000000000000000000000000000000000000020)
                mstore(0x20, 0x0000000000000000000000000000000000000000000000000000000000000022)
                mstore(0x40,sload(uriPos()))
                mstore(0x60, sload(add(0x20,uriPos())))
                
            }

        /* ---------- Events ---------- */
            function emitTransferSingle(operator, from, to, id, amount) {
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0, id)
                mstore(0x20, amount)
                log4(0, 0x40, signatureHash, operator, from, to)
            }


            function emitTransferBatch(operator, from, to, id_length_offset,amount_length_offset,id_length_location,amount_length_location,id_length,amount_length) {
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                let offsetFor2ndArray := add(mul(0x20,id_length),0x60) // offset value for the data part of the second array (elements of first array + the 2 offsets + first length)
                mstore(fmp(), 0x0000000000000000000000000000000000000000000000000000000000000040)
                mstore(
                    add(fmp(),0x20),  // memory location 
                     offsetFor2ndArray 
                ) 
                calldatacopy(add(fmp(),0x40),id_length_location,add(0x20,mul(0x20,id_length))) // size is the length + 0x20 to include length
                calldatacopy(add(fmp(),offsetFor2ndArray), amount_length_location, add(0x20,mul(0x20,id_length)))
                let totalElements := add(amount_length, id_length)
                let totalElementsSize := mul(0x40,totalElements)
                // let totalSize:= add(0x40,totalElementsSize)
                log4(fmp(),totalElementsSize, signatureHash, operator, from, to)
            }



        /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function doSafeTransferAcceptanceCheck(operator,from,to,id,amount,data_offset) -> success {
                success:= 0
                if isContract(to) {
                    let data_new_offset := add(0x20, data_offset)
                    // load the arguments
                    // function signature `onERC1155Received(address,address,uint256,uint256,bytes)`
                    mstore(fmp(),0xf23a6e6100000000000000000000000000000000000000000000000000000000) 
                    mstore(add(fmp(),4), operator) // caller()
                    mstore(add(fmp(),36), from) // caller()
                    // mstore(add(fmp(),68), to) 
                    mstore(add(fmp(),68), id)
                    mstore(add(fmp(),100), amount)
                    mstore(add(fmp(),132), data_new_offset)
                    calldatacopy(add(fmp(),164),0x84,sub(calldatasize(),0x84))  
                    success:= call(gas(),to, 0, fmp(),  add(calldatasize(),0x20),  add(add(fmp(),calldatasize()),0x1c), 4)
                    require(eq(mload(add(add(fmp(),calldatasize()),0x1c)),0xf23a6e6100000000000000000000000000000000000000000000000000000000))
                    
                }
            }

            function doSafeBatchTransferAcceptanceCheck(operator,from,to,ids_offset,amounts_offset,data_offset) -> success {
                success:= 0
                let ids_new_offset := add(0x20,ids_offset)
                let amounts_new_offset := add(0x20,amounts_offset)
                let data_new_offset := add(0x20, data_offset)
                if isContract(to) {
                    // function signature `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`
                    mstore(fmp(),0xbc197c8100000000000000000000000000000000000000000000000000000000) 
                    mstore(add(fmp(),4), operator) // caller()
                    mstore(add(fmp(),36), from) // caller()
                    mstore(add(fmp(),68), ids_new_offset) 
                    mstore(add(fmp(),100), amounts_new_offset)
                    mstore(add(fmp(),132), data_new_offset)
                    calldatacopy(add(fmp(),164),0x84,sub(calldatasize(),0x84))   
                    success:= call(gas(),to, 0, fmp(),  add(calldatasize(),0x20), add(add(fmp(),calldatasize()),0x1c), 4)  
                    require(eq(mload(add(add(fmp(),calldatasize()),0x1c)),0xbc197c8100000000000000000000000000000000000000000000000000000000))
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
        }


    }
}