import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('signs transactions', () async {
    final credentials = EthPrivateKey(hexToBytes(''));
    final transaction = Transaction(
      from: await credentials.extractAddress(),
    );

    final signature = await TransactionSigner()
        .sign(credentials: credentials, transaction: transaction);
  });
}
