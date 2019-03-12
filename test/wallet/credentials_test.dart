import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('Credentials', () {
    test("won't accept invalid keys", () {
      expect(() => Credentials.fromPrivateKey(BigInt.from(-1)),
          throwsArgumentError);
      expect(
          () => Credentials.fromPrivateKeyHex(
              'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141'),
          throwsArgumentError);
    });

    test('can be derived from private key', () {
      expect(
          Credentials.fromPrivateKeyHex(
                  'c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3')
              .address
              .hexEip55,
          equals('0x627306090abaB3A6e1400e9345bC60c78a8BEf57'));
      expect(
          Credentials.fromPrivateKeyHex(
                  'ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f')
              .address
              .hexEip55,
          equals('0xf17f52151EbEF6C7334FAD080c5704D77216b732'));
    });
  });
}
