import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String privateKey =
    'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e';
const String rpcUrl = 'http://localhost:7545';

Future<void> main() async {
  // start a client we can use to send transactions
  final client = Web3Client(rpcUrl, Client());

  final credentials = EthPrivateKey.fromHex(privateKey);
  final address = credentials.address;

  print(address.hexEip55);
  print(await client.getBalance(address));

  await client.sendTransaction(
    credentials,
    Transaction(
      to: EthereumAddress.fromHex('0xC914Bb2ba888e3367bcecEb5C2d99DF7C7423706'),
      gasPrice: EtherAmount.inWei(BigInt.one),
      maxGas: 100000,
      value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
    ),
  );

  await client.dispose();
}
