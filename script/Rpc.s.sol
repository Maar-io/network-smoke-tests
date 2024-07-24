// SPDX-License-Identifier: MIT
// forge script script/Rpc.s.sol --ffi
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

contract TestRPCScript is Script, Test {
    string rpcUrl = "";
    string[] inputs = new string[](8);

    struct ResponseStruct {
        string jsonrpc;
        uint256 myid;
        string result;
    }

    function init() public {
        rpcUrl = vm.rpcUrl("osaki");

        inputs[0] = "curl";
        inputs[1] = "-X";
        inputs[2] = "POST";
        inputs[3] = "-H";
        inputs[4] = "Content-Type: application/json";
        inputs[5] = "--data";
        inputs[7] = rpcUrl;
    }

    function run() external {
        // vm.startBroadcast();
        init();
        ethBlockNumber();
        ethGetBalance();
        ethGetTransactionCount();

        error400();
        // vm.stopBroadcast();
    }
    function parseJsonResponse(
        string memory jsonString
    ) public pure returns (ResponseStruct memory) {
        string memory jsonrpc = vm.parseJsonString(jsonString, ".jsonrpc");
        uint256 myid = vm.parseJsonUint(jsonString, ".id");
        string memory result = vm.parseJsonString(jsonString, ".result");

        return ResponseStruct({jsonrpc: jsonrpc, myid: myid, result: result});
    }

    function ethBlockNumber() public {
        // Prepare the curl command with proper argument separation
        inputs[6] = string(
            abi.encodePacked(
                '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
            )
        );

        // Execute the curl command using ffi
        bytes memory res = vm.ffi(inputs);

        string memory response = string(res);
        ResponseStruct memory responseStruct = parseJsonResponse(response);
        assertTrue(bytes(responseStruct.result).length > 0);
        console.log("[OK]  eth_blockNumber response: ", responseStruct.result);
    }

    function ethGetBalance() public {
        inputs[6] = string(
            abi.encodePacked(
                '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x911d82b108804A18022d0A2621B2Fc608DEF6FCA", "latest"],"id":1}'
            )
        );

        // Execute the curl command using ffi
        bytes memory res = vm.ffi(inputs);

        string memory response = string(res);
        ResponseStruct memory responseStruct = parseJsonResponse(response);
        assertTrue(bytes(responseStruct.result).length > 0);
        console.log("[OK]  eth_getBalance response: ", responseStruct.result);
    }

    function ethGetTransactionCount() public {
        inputs[6] = string(
            abi.encodePacked(
                '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0x911d82b108804A18022d0A2621B2Fc608DEF6FCA", "latest"],"id":1}'
            )
        );

        // Execute the curl command using ffi
        bytes memory res = vm.ffi(inputs);

        string memory response = string(res);
        ResponseStruct memory responseStruct = parseJsonResponse(response);
        assertTrue(bytes(responseStruct.result).length > 0);
        console.log(
            "[OK]  eth_getTransactionCount response: ",
            responseStruct.result
        );
    }

    function error400() public {
        // curl -X POST "<RPC_URL>%" \
        //  -H "Content-Type: application/json; charset=invalid" \
        //  -d "this is not a valid JSON string"

        inputs[6] = string(
            abi.encodePacked(
                '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
            )
        );
        inputs[7] = string(abi.encodePacked(rpcUrl, "%")); // Execute the curl command using ffi
        bytes memory res = vm.ffi(inputs);

        string memory response = string(res);
        console.log("response: [%s]", response);

        // Convert response to bytes for slicing
        bytes memory responseBytes = bytes(response);
        // Ensure there are at least 11 bytes to slice
        bytes memory first11Bytes = responseBytes.length >= 11
            ? new bytes(11)
            : new bytes(responseBytes.length);
        for (uint i = 0; i < first11Bytes.length; i++) {
            first11Bytes[i] = responseBytes[i];
        }

        // Convert the first 11 bytes back to a string if needed
        string memory first11String = string(first11Bytes);
        // Use the sliced string for comparison
        assertTrue(
            keccak256(abi.encodePacked(first11String)) ==
                keccak256(abi.encodePacked("Bad request"))
        );
        console.log("[OK]  expecting Bad request response: ", first11String);
    }
}
