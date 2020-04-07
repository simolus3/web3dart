import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:web3dart/metamask.dart';

Future<void> main() async {
  if (!MetaMask.isSupported) {
    window.alert('Your browser does not MetaMask');
    return;
  }

  final metamask = MetaMask();
  final accounts = await metamask.enable();

  querySelector('#output').text = 'Connected. Accounts: $accounts';

  print(await accounts.single
      .signPersonalMessage(Uint8List.fromList(utf8.encode('foo'))));
}
