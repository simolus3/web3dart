import 'dart:convert';

import 'package:test/test.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

import 'example_keystores.dart' as data;

void main() {
  final wallets = json.decode(data.content) as Map;

  // ignore: cascade_invocations
  wallets.forEach((testName, content) {
    test('unlocks wallet $testName', () {
      final password = content['password'] as String;
      final privateKey = content['priv'] as String;
      final walletData = content['json'] as Map;

      final wallet = Wallet.fromJson(json.encode(walletData), password);
      expect(bytesToHex(wallet.privateKey.privateKey), privateKey);

      final encodedWallet = json.decode(wallet.toJson()) as Map;

      expect(encodedWallet['crypto']['ciphertext'],
          walletData['crypto']['ciphertext']);
    }, tags: 'expensive');
  });
}
