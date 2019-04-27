import 'dart:io';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart' show join, dirname;

const String rpcUrl = 'http://localhost:7545';
const String privateKey =
    'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e';

final EthereumAddress contractAddr =
    EthereumAddress.fromHex('0x9Af64C6D3A93D7f11426723dCDE850d667C994ca');
final EthereumAddress receiver =
    EthereumAddress.fromHex('0xC914Bb2ba888e3367bcecEb5C2d99DF7C7423706');

final File abiFile = File(join(dirname(Platform.script.path), 'abi.json'));

/*
Examples that deal with contracts. The contract used here is from the truffle
example:

contract MetaCoin {
	mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	constructor() public {
		balances[tx.origin] = 10000;
	}

	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}

	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}

The compiled ABI of this contract is available at abi.json
 */

void main() async {
  // establish a connection to the ethereum rpc node
  final client = Web3Client(rpcUrl, Client());
  final credentials = await client.credentialsFromPrivateKey(privateKey);
  final ownAddress = await credentials.extractAddress();

  // read the contract abi and tell web3dart where it's deployed (contractAddr)
  final abiCode = await abiFile.readAsString();
  final contract =
      DeployedContract(ContractAbi.fromJson(abiCode, 'MetaCoin'), contractAddr);

  // extracting some functions and events that we'll need later
  final transferEvent = contract.event('Transfer');
  final balanceFunction = contract.function('getBalance');
  final sendFunction = contract.function('sendCoin');

  // listen for the Transfer event when it's emitted by the contract above
  client
      .events(FilterOptions.events(contract: contract, event: transferEvent))
      .listen((event) {
    print(event);
  });

  // check our balance in MetaCoins by calling the appropriate function
  final balance = await client.call(
      contract: contract, function: balanceFunction, params: [ownAddress]);
  print('We have ${balance.first} MetaCoins');

  // send all our MetaCoins to the other address by calling the sendCoin
  // function
  await client.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: contract,
      function: sendFunction,
      parameters: [receiver, balance.first],
    ),
  );

  await client.dispose();
}
