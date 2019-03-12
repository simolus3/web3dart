import 'dart:async';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String privateKey =
    'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e';
const String rpcUrl = 'http://localhost:7545';

// todo test TransactionInformation parsing

Future<Null> main() async {
  final httpClient = Client();
  final client = Web3Client(rpcUrl, httpClient)..printErrors = true;

  final credentials = Credentials.fromPrivateKeyHex(privateKey);

  print(await client.getBalance(credentials.address));

  // prepare a transaction
  await Transaction(keys: credentials, maximumGas: 100000)
      .prepareForSimpleTransaction(
          //that will transfer 2 ether
          EthereumAddress('0xC914Bb2ba888e3367bcecEb5C2d99DF7C7423706'),
          EtherAmount.fromUnitAndValue(EtherUnit.ether, 2))
      .send(client); //and send.
}
