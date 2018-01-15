import 'dart:async';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

/*
This is the ABI for the following contract:

pragma solidity ^0.4.17;
contract TestContract {
    string public message;
    function writeMessage(string _msg) external {
        message = _msg;
    }
    function getMessage() public view returns (string _msg) {
        return message;
    }
}
 */

const String ABI_JSON = '[{"constant":false,"inputs":[{"name":"_msg","type":"string"}],"name":"writeMessage","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"getMessage","outputs":[{"name":"_msg","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"message","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"}]';

const String _PRIVATE_KEY = "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";
const String _URL = "http://localhost:7545";

Future main() async {
	var httpClient = new Client();
	Web3Client client = new Web3Client(_URL, httpClient);

	var credentials = Credentials.fromHexPrivateKey(_PRIVATE_KEY);

	var abi = ContractABI.parseFromJSON(ABI_JSON, "TestContract");

	//replace with address of the deployed contract
	var contract = new DeployedContract(abi, "0x345ca3e014aaf5dca488057592ee47305d9b3e10", client, credentials);

	//call the writeMessage function
	var writeMessage = contract.findFunctionsByName("writeMessage").first;
	await new Transaction(keys: credentials, maximumGas: 1000000)
			.prepareForCall(contract, writeMessage, ["Message on the Blockchain!"])
			.send(client);

	/* When not using Ganache with auto-mining, you would have to wait until the
		 first transaction has been mined here. */

	var getMessage = contract.findFunctionsByName("getMessage").first;
	var data = await new Transaction(keys: credentials, maximumGas: 0)
		.prepareForCall(contract, getMessage, [])
		.call(client);

	print(data); //should print [Message on the Blockchain!]
}