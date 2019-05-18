import 'dart:io';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart' show join, dirname;
import 'package:web_socket_channel/io.dart';

const String rpcUrl = 'http://localhost:7545';
const String wsUrl = 'ws://localhost:7545';

const String privateKey =
    '85d2242ae1b7759934d4b0d4f0d62d666cf7d73e21dbd09d73c7de266b72a25a';

final EthereumAddress contractAddr =
    EthereumAddress.fromHex('0xf451659CF5688e31a31fC3316efbcC2339A490Fb');
final EthereumAddress receiver =
    EthereumAddress.fromHex('0x6c87E1a114C3379BEc929f6356c5263d62542C13');

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

The ABI of this contract is available at abi.json
 */

void main() async {
  // establish a connection to the ethereum rpc node. The socketConnector
  // property allows more efficient event streams over websocket instead of
  // http-polls. However, the socketConnector property is experimental.
  final client = Web3Client(rpcUrl, Client(), socketConnector: () {
    return IOWebSocketChannel.connect(wsUrl).cast<String>();
  });
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
  final subscription = client
      .events(FilterOptions.events(contract: contract, event: transferEvent))
      .take(1)
      .listen((event) {
    final decoded = transferEvent.decodeResults(event.topics, event.data);

    final from = decoded[0] as EthereumAddress;
    final to = decoded[1] as EthereumAddress;
    final value = decoded[2] as BigInt;

    print('$from sent $value MetaCoins to $to');
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

  await subscription.asFuture();
  await subscription.cancel();

  await client.dispose();
}
