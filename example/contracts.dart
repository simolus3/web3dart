import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

import 'token.g.dart';

const String rpcUrl = 'http://localhost:8545';
const String wsUrl = 'ws://localhost:8545';

const String privateKey =
    '9a43d93a50b622761d88c80c90567c02c82442746335a01b72f49b3c867c037d';

final EthereumAddress contractAddr =
    EthereumAddress.fromHex('0xeE9312C22890e0Bd9a9bB37Fd17572180F4Fc68a');
final EthereumAddress receiver =
    EthereumAddress.fromHex('0x6c87E1a114C3379BEc929f6356c5263d62542C13');

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
To generate contract classes, add a dependency on web3dart and build_runner.
Running `dart pub run build_runner build` (or `flutter pub ...` if you're using
Flutter) will generate classes for an .abi.json file.
 */

Future<void> main() async {
  // establish a connection to the ethereum rpc node. The socketConnector
  // property allows more efficient event streams over websocket instead of
  // http-polls. However, the socketConnector property is experimental.
  final client = Web3Client(rpcUrl, Client(), socketConnector: () {
    return IOWebSocketChannel.connect(wsUrl).cast<String>();
  });
  final credentials = EthPrivateKey.fromHex(privateKey);
  final ownAddress = await credentials.extractAddress();

  // read the contract abi and tell web3dart where it's deployed (contractAddr)
  final token = Token(address: contractAddr, client: client);

  // listen for the Transfer event when it's emitted by the contract above
  final subscription = token.transferEvents().take(1).listen((event) {
    print('${event.from} sent ${event.value} MetaCoins to ${event.to}!');
  });

  // check our balance in MetaCoins by calling the appropriate function
  final balance = await token.getBalance(ownAddress);
  print('We have $balance MetaCoins');

  // send all our MetaCoins to the other address by calling the sendCoin
  // function
  await token.sendCoin(receiver, balance, credentials: credentials);

  await subscription.asFuture();
  await subscription.cancel();

  await client.dispose();
}
