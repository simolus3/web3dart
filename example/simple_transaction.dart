import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String privateKey =
    'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e';
const String rpcUrl = 'http://localhost:7545';

void main() async {
  final client = Web3Client(rpcUrl, Client(), enableBackgroundIsolate: true);

  final credentials = await client.credentialsFromPrivateKey(privateKey);
  final address = await credentials.extractAddress();

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
    fetchChainIdFromNetworkId: false,
  );
}
