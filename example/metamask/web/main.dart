import 'dart:html';

import 'package:web3dart/metamask.dart';
import 'package:web3dart/web3dart.dart';

Future<void> main() async {
  if (!MetaMask.isSupported) {
    window.alert('Your browser does not MetaMask');
    return;
  }

  final metamask = MetaMask();
  final accounts = await metamask.enable();

  querySelector('#output').text = 'Connected. Accounts: $accounts';

  final client = Web3Client.custom(metamask, signatureComputers: const [
    MetaMaskSignatures(),
  ]);
  print(await client.coinbaseAddress());

  await client.sendTransaction(
    accounts.single,
    Transaction(
      to: EthereumAddress.fromHex('0x6c87E1a114C3379BEc929f6356c5263d62542C13'),
      value: EtherAmount.inWei(BigInt.from(1000000)),
    ),
  );
}
