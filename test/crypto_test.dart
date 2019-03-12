import 'package:test_api/test_api.dart';
import 'package:web3dart/src/utils/crypto.dart';
import 'package:web3dart/src/utils/numbers.dart';

void main() {
  final privateKeyHex = '0x60cf347dbc59d31c1358c8e5cf5e45b822ab85b79cb32a9f3d98184779a9efc2';

  test('creates public keys from private keys', () {
    expect(bytesToHex(privateKeyToPublic(hexToBytes(privateKeyHex))), '1e7bcc70c72770dbb72fea022e8a6d07f814d2ebe4de9ae3f7af75bf706902a7b73ff919898c836396a6b0c96812c3213b99372050853bd1678da0ead14487d7');
  });
}