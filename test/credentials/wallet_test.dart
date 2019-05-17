import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test_api/test_api.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

void main() {
  final file = File(join('test', 'credentials', 'example_keystores.json'));
  final wallets = json.decode(file.readAsStringSync()) as Map;

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
    }, timeout: const Timeout.factor(2));
  });
}
