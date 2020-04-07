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

  final client = Web3Client.custom(metamask);
  print(await client.coinbaseAddress());
}
