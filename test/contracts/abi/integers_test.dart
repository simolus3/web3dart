import 'package:test_api/test_api.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

import 'utils.dart';

Map<BigInt, String> _uintEncoded = {
  BigInt.zero:
      '0000000000000000000000000000000000000000000000000000000000000000',
  BigInt.from(0x7fffffffffffffff):
      '0000000000000000000000000000000000000000000000007fffffffffffffff',
  BigInt.parse(
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          radix: 16):
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
};

Map<BigInt, String> _intEncoded = {
  BigInt.zero:
      '0000000000000000000000000000000000000000000000000000000000000000',
  BigInt.from(9223372036854775807):
      '0000000000000000000000000000000000000000000000007fffffffffffffff',
  BigInt.from(-9223372036854775808):
      'ffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000',
  BigInt.from(-1):
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
};

void main() {
  group('uints', () {
    _uintEncoded.forEach((i, val) {
      test('encode $i as $val', () {
        expectEncodes(UintType(), i, val);
      });

      test('decodes $val as $i', () {
        final bytes = hexToBytes(val).buffer;
        expect(UintType().decode(bytes, 0), DecodingResult(i, 32));
      });
    });
  });

  group('ints', () {
    _intEncoded.forEach((i, val) {
      test('encode $i as $val', () {
        expectEncodes(IntType(), i, val);
      });

      test('decodes $val as $i', () {
        final bytes = hexToBytes(val).buffer;
        expect(IntType().decode(bytes, 0), DecodingResult(i, 32));
      });
    });
  });

  group('addresses', () {
    final address =
        EthereumAddress.fromHex('0x52908400098527886E0F7030069857D2E4169EE7');

    final encoded =
        '00000000000000000000000052908400098527886e0f7030069857d2e4169ee7';

    test('encode', () {
      expectEncodes(const AddressType(), address, encoded);
    });

    test('decode', () {
      final bytes = hexToBytes(encoded).buffer;
      expect(const AddressType().decode(bytes, 0), DecodingResult(address, 32));
    });
  });

  group('booleans', () {
    final falseEncoded = '0000000000000000000000000000000000000000000000000000000000000000';
    final trueEncoded = '0000000000000000000000000000000000000000000000000000000000000001';

    test('encode', () {
      expectEncodes(const BoolType(), false,
          falseEncoded);
      expectEncodes(const BoolType(), true,
          trueEncoded);
    });

    test('decode', () {
      final falseBytes = hexToBytes(falseEncoded).buffer;
      expect(const BoolType().decode(falseBytes, 0), DecodingResult(false, 32));

      final trueBytes = hexToBytes(trueEncoded).buffer;
      expect(const BoolType().decode(trueBytes, 0), DecodingResult(true, 32));
    });
  });
}
