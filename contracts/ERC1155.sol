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
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }

            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
                returnArray(getArrayLength(0), balanceOfBatch(getFirstElementPosition(0), getFirstElementPosition(1), getArrayLength(0)))
            }

            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1),decodeAsUint(2), decodeAsUint(3))
            }

            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */{
                safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), getFirstElementPosition(2), getFirstElementPosition(3), getArrayLength(2), getArrayLength(3))
            }

            case 0x731133e9 /* "mint(address,uint25,uint25,bytes)" */ {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2)) //account,tokenId,amount
            }
            
            // mintBatch(address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data)
            case 0x1f7fdffa /* "mintBatch(address,uint256[],uint256[],bytes)" */ {
                mintBatch(decodeAsAddress(0),getFirstElementPosition(1),getFirstElementPosition(2),getArrayLength(1),getArrayLength(2))
            }

            // function burn(address from,uint256 id,uint256 amount)
            case 0xf5298aca /* "burn(address,uint256,uint256)" */{
                burn(decodeAsAddress(0),decodeAsUint(1),decodeAsUint(2))
            }

            // function burnBatch(address from,uint256[] memory ids,uint256[] memory amounts)
            case 0x6b20c454 /* "burnBatch(address,uint256[],uint256[])" */{
                burnBatch(decodeAsAddress(0), getFirstElementPosition(1),getFirstElementPosition(2),getArrayLength(1),getArrayLength(2))
            }

            case 0x0e89341c /* "uri(uint256)" */ {
                uri()
            }

            // function setApprovalForAll(operator, approval)
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */{
                setApprovalForAll(decodeAsAddress(0),decodeAsUint(1))
            }

            // function isApprovedForAll(address account, address operator)
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
                returnUint(isApprovedForAll(decodeAsAddress(0),decodeAsAddress(1)))
            }
            // function supportsInterface(bytes4 interfaceId)
            case 0x01ffc9a7 /* "supportsInterface(bytes4)" */{
                returnUint(or(eq(calldataload(0x04),0xd9b67a2600000000000000000000000000000000000000000000000000000000), eq(calldataload(0x04),0x01ffc9a700000000000000000000000000000000000000000000000000000000)))
            }

            default {
                mstore(0x00,selector())
                return(0,0x20)
            }

            /* Core functions */ 
            function balanceOf(account, tokenId) -> bal {
                // Returns the balance of the given token of the given account 
                // account: address
                // tokenId: uint256
                bal := sload(accountToStorageOffset(account, tokenId))
            }

            function balanceOfBatch(accountsStart, idsStart, accountsSize) -> balancesStart {
                // Returns location of the first element of the balances array in memory
                // accountsStart: memory slot
                // idsStart: memory slot
                // accountsSize: uint256
                balancesStart:= fmp()
                for{let i := 0} lte(i,mul(accountsSize,0x20)){i:= add(i,0x20)}{
                    mstore(fmp(),balanceOf(calldataload(add(accountsStart,i)),calldataload(add(idsStart,i))))
                    updateFmp(0x20)
                }
            }

            function safeTransferFrom(from, to, tokenId, amount){
                // Transfers tokens from the 'from' address to the 'to' address
                // Reverts if 'to' address is the zero address
                // Returns true if successful 
                // from: address
                // to: address
                // tokenId: uint256
                // amount: uint256

                revertIfZeroAddress(to)
                require(or(eq(caller(),from),isApprovedForAll(from,caller())))
                transfer(from,to,tokenId,amount)
                returnTrue()
            }

            function safeBatchTransferFrom(from,to,tokenIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength){
                // Transfers different tokens from 'from' address to 'to' address in one transaction
                // Reverts if 'to' address is the zero address
                // Returns true if successful 
                // from: address
                // to: address
                // tokenIdFirstElementPosition: memory slot
                // amountFirstElementPosition: memory slot
                // topicLength: uint256
                // amountLength: uint256
                revertIfZeroAddress(to)
                require(eq(topicIdLength,amountLength))
                require(or(eq(caller(),from),isApprovedForAll(from,caller())))

                batchTransfer(from,to,tokenIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength)
                emitTransferBatch(caller(), from, to,tokenIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength)

                // first element position slots are subtracted by 32-bytes before passing to the function because the position of
                // the slot holding the value of the length of the array is required by the function
                require(doSafeBatchTransferAcceptanceCheck(caller(),from,to,sub(tokenIdFirstElementPosition,0x20),sub(amountFirstElementPosition,0x20),calldataload(0x84)))
                returnTrue()
            }

            function mint(to,tokenId,amount) {
                // Transfers token with given token id to 'to' address from zero address
                // Reverts if 'to' address is the zero address
                // returns true if successful
                // to: address
                // tokenId: uint256
                // amount: uint256

                revertIfZeroAddress(to)
                transfer(0x00,to,tokenId,amount)
                returnTrue()
            }

            function mintBatch(to,topicIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength){
                // Transfers a given amount of tokens with corresponding token ids to 'to' address from zero address
                // Reverts if 'to' address is the zero address
                // Reverts if topic ids array length does not equal the amounts array length
                // returns true if successful
                // to: address
                // tokenIdFirstElementPosition: memory slot
                // amountFirstElementPosition: memory slot
                // topicLength: uint256
                // amountLength: uint256
                
                revertIfZeroAddress(to)
                require(eq(topicIdLength,amountLength))
                batchTransfer(0x00,to,topicIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength)
                emitTransferBatch(caller(), 0x00, to,topicIdFirstElementPosition,amountFirstElementPosition,topicIdLength,amountLength)
                require(doSafeBatchTransferAcceptanceCheck(caller(),0x00,to,sub(topicIdFirstElementPosition,0x20),sub(amountFirstElementPosition,0x20),calldataload(0x64)))
                returnTrue()
            }

            function burn(from, topicId, amount){
                // to must be set to the zero address
                transfer(from,0x00,topicId,amount)
                returnTrue()
            }

            function burnBatch(from, tokenIdFirstElementPosition, amountFirstElementPosition, tokenidLength, amountLength){
                revertIfZeroAddress(from)
                require(eq(tokenIdLength,amountLength))
                batchTransfer(from,0x00,tokenIdFirstElementPosition,amountFirstElementPosition,tokenIdLength,amountLength)
                emitTransferBatch(caller(), from, 0x00,tokenIdFirstElementPosition,amountFirstElementPosition,tokenIdLength,amountLength)
                returnTrue()
            }

            function uri(){
                loadUriToMemory()
                return(0x00, 0x80)
            }

            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function getArrayLength(offset) -> length {
                let pos := add(4, mul(offset, 0x20))
                let id_length_offset := calldataload(pos)
                let id_length_location := add(4, id_length_offset)
                length := calldataload(id_length_location)
            }
            
            function getFirstElementPosition(offset) -> e {
                let pos := add(4, mul(offset, 0x20))
                let id_length_offset := calldataload(pos)
                let id_length_location := add(4, id_length_offset)
                let id_length := calldataload(id_length_location)
                e := add(id_length_location, 0x20)
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
            function returnArray(arrayLength, arrayOffset){
                mstore(fmp(),0x20)
                mstore(add(fmp(),0x20),arrayLength)
                for { let i := 0x00} lte(i, mul(arrayLength,0x20)) { i := add(i, 0x20) } {
                    mstore(add(add(fmp(),0x40),i),mload(add(arrayOffset,i)))
                }
                return(fmp(),add(0x40,mul(arrayLength,0x020)))
            }

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
            }

        /* ---------- Storage Layout ----------*/

            function ownerPos() -> p { p := 0x00 }
            function uriPos() -> p { p := 0x20 }
            function accountToStorageOffset(account, tokenId) -> offset {
                mstore(0x00,0x80)
                mstore(0x20,tokenId)
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



            function owner() -> o {
                o := sload(ownerPos())
            }

            function setApprovalForAll(operator,approved){
                require(notEq(caller(),operator))
                sstore(allowanceStorageOffset(caller(),operator), approved)
                emitApprovalForAll(caller(),operator,approved)
            }

            function isApprovedForAll(account, operator) -> approved {
                approved := sload(allowanceStorageOffset(account, operator))
            }



            function transfer(from,to,tokenId,amount) {
                if gt(to,0){
                    addTo(to,tokenId,amount)
                }
                
                
                // Only happens during transfers or burns
                if gt(from,0){
                    // TO DO: add or condition once is ApprovedForAll is implemented
                    if gt(to,0){
                        require(or(eq(caller(),from),isApprovedForAll(from,caller())))
                    }
                    
                    
                    // making sure the sender has enough tokens to send
                    let slot:= accountToStorageOffset(from, tokenId)
                    let bal := sload(slot)
                    require(gte(bal, amount))

                    
                    subtractTo(from,tokenId,amount)
                }
    
                emitTransferSingle(caller(), from, to, tokenId, amount)
                if isContract(to){
                    let data_length_offset := calldataload(0x64)
                    require(doSafeTransferAcceptanceCheck(caller(),0x00,to,tokenId,amount,data_length_offset))
                } 
            }  

            function batchTransfer(from, to, tokenIdStartPosition, amountStartPosition, tokenIdSize, amountSize){
                if gt(to,0){
                    addToBatch(to, amountStartPosition, tokenIdStartPosition, tokenIdSize)
                }
                if gt(from,0){
                    subtractToBatch(from, amountStartPosition, tokenIdStartPosition, tokenIdSize)
                }
            }

            function addTo(account,tokenId,amount) {
                let slot:= accountToStorageOffset(account, tokenId)
                let bal := sload(slot)
                bal := safeAdd(bal, amount)
                sstore(slot, bal)
            }

            function addToBatch(account, amountOffset, tokenIdOffset, batchSize){
                for { let i := 0x00} lte(i, mul(batchSize,0x20)) { i := add(i, 0x20) } {
                    let tokenId := calldataload(add(i, tokenIdOffset))
                    let amount := calldataload(add(i, amountOffset))
                    addTo(account,tokenId,amount)
                }
            }

            function subtractTo(account,tokenId,amount) {
                let slot:= accountToStorageOffset(account, tokenId)
                let bal := sload(slot)
                bal := sub(bal, amount)
                sstore(slot, bal)
            } 

            function subtractToBatch(account, amountOffset, tokenIdOffset, batchSize){
                for { let i := 0x00} lte(i, mul(batchSize,0x20)) { i := add(i, 0x20) } {
                    let tokenId := calldataload(add(i, tokenIdOffset))
                    let amount := calldataload(add(i, amountOffset))
                    subtractTo(account,tokenId,amount)
                }
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


            function emitTransferBatch(operator, from, to,topicIdStart,amountStart,topicIdLength,amountLength) {
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                let offsetFor2ndArray := add(mul(0x20,topicIdLength),0x60) // offset value for the data part of the second array (elements of first array + the 2 offsets + first length)
                mstore(fmp(), 0x0000000000000000000000000000000000000000000000000000000000000040)
                mstore(
                    add(fmp(),0x20),  // memory location 
                     offsetFor2ndArray 
                ) 
                calldatacopy(add(fmp(),0x40),sub(topicIdStart,0x20),add(0x20,mul(0x20,topicIdLength))) // size is the length + 0x20 to include length
                calldatacopy(add(fmp(),offsetFor2ndArray), sub(amountStart,0x20), add(0x20,mul(0x20,amountLength)))
                let totalElements := add(topicIdLength, amountLength)
                let totalElementsSize := mul(0x40,totalElements)
                // let totalSize:= add(0x40,totalElementsSize)
                log4(fmp(),totalElementsSize, signatureHash, operator, from, to)
            }

            function emitApprovalForAll(account, operator, approved){
                let signatureHash:= 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0, account)
                mstore(0x20, operator)
                mstore(0x40, approved)
                log4(0, 0, signatureHash, account, operator, approved)
            }



        /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function notEq(a,b) -> r {
                r:= iszero(eq(a,b))
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
                if iszero(isContract(to)) {
                    success:=1
                }


            }

            function doSafeBatchTransferAcceptanceCheck(operator,from,to,ids_offset,amounts_offset,data_offset) -> success {
                success:= 0
                // adjustments 
                let ids_new_offset := add(0x1c,ids_offset)
                let amounts_new_offset := add(0x1c,amounts_offset)
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
                if iszero(isContract(to)) {
                    success:=1
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
                ic := gt(extcodesize(addr),0)
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }


    }
}