import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  final examples = [
    '0x52908400098527886E0F7030069857D2E4169EE7',
    '0x8617E340B3D01FA5F11F306F4090FD50E238070D',
    '0xde709f2102306220921060314715629080e2fb77',
    '0x27b1fdb04752bbc536007a920d24acb045561c26',
    '0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
    '0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359',
    '0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB',
    '0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb'
  ];

  group('Validating addresses', () {
    test('succeeds with valid numbers', () {
      expect(EthereumAddress.fromNumber(BigInt.one), isNotNull);
      expect(
          EthereumAddress.fromNumber(BigInt.parse(
              '627306090abaB3A6e1400e9345bC60c78a8BEf57',
              radix: 16)),
          isNotNull);
    });

    test('fails on invalid numbers', () {
      expect(() => EthereumAddress.fromNumber(BigInt.parse('-3')),
          throwsArgumentError);
      expect(
          () => EthereumAddress.fromNumber(BigInt.parse('F' * 41, radix: 16)),
          throwsArgumentError);
    });

    test('fails on invalid hex', () {
      expect(
          () => EthereumAddress('\$627306090abaB3A6e1400e9345bC60c78a8BEf57'),
          throwsArgumentError);
      expect(() => EthereumAddress('0x7306090abaB3A6e1400e9345bC60c78a8BEf57'),
          throwsArgumentError);
    });

    test('succeeds with valid hex', () {
      for (var example in examples) {
        expect(EthereumAddress(example), isNotNull);
      }
    });

    test('fails on hex violating EIP 55', () {
      expect(
          () => EthereumAddress('\$627306090aBaB3A6E1400e9345bC60c78a8BEf57'),
          throwsArgumentError);
    });
  });

  group('Printing addresses', () {
    test('properly padds', () {
      for (var example in examples) {
        expect(EthereumAddress(example).hexNo0x, hasLength(equals(40)));
      }
    });

    test('respects EIP 55', () {
      for (var example in examples) {
        expect(EthereumAddress(example).hexEip55, equals(example));
      }
    });
  });
}
