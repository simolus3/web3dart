import 'dart:convert' show utf8;

import 'package:test/test.dart';
import 'package:web3dart/src/contracts/types/arrays.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/src/contracts/types/type.dart';

const Map<bool, String> _boolEncoded = const {
  false: '0000000000000000000000000000000000000000000000000000000000000000',
  true: '0000000000000000000000000000000000000000000000000000000000000001',
};

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

void testEncode<T>(ABIType<T> type, Map<T, String> data) {
  data.forEach((value, encoded) {
    expect(type.encode(value), equals(encoded));
  });
}

void testDecode<T>(ABIType<T> type, Map<T, String> data) {
  data.forEach((value, encoded) {
    expect(type.decode(encoded).item1, equals(value));
  });
}

void main() {
  group('Utils', () {
    test('Padding', () {
      final type = BoolType();

      expect(type.calculatePadLen(2), equals(62));
      expect(type.calculatePadLen(131), equals(61));
      expect(type.calculatePadLen(0), equals(64));
      expect(type.calculatePadLen(128), equals(0));
    });
  });

  final boolType = BoolType();
  final uint256Type = UintType();
  final int256Type = IntType();

  group('Encode', () {
    test('bools', () {
      testEncode(boolType, _boolEncoded);
    });

    test('uints', () {
      testEncode(uint256Type, _uintEncoded);
    });

    test('ints', () {
      testEncode(int256Type, _intEncoded);
    });

    test('static bytes', () {
      expect(
          StaticLengthBytes(6).encode([0, 1, 2, 3, 4, 5]),
          equals(
              '0001020304050000000000000000000000000000000000000000000000000000'));
      expect(StaticLengthBytes(1).encode([0]), equals('0' * 64));
      expect(
          StaticLengthBytes(4).encode(utf8.encode('dave')),
          equals(
              '6461766500000000000000000000000000000000000000000000000000000000'));
    });
  });

  group('Decode', () {
    test('bools', () {
      testDecode(boolType, _boolEncoded);
    });

    test('uints', () {
      testDecode(uint256Type, _uintEncoded);
    });

    test('ints', () {
      testDecode(int256Type, _intEncoded);
    });
  });

  group('Parameter validation', () {
    test("Invalid uints can't be created", () {
      expect(() => UintType(M: 54), throwsArgumentError); //not divisible by 8
      expect(() => UintType(M: 0), throwsArgumentError);
      expect(() => UintType(M: 1024), throwsArgumentError);
      expect(() => UintType(M: -8), throwsArgumentError);

      expect(() => UintType(M: 8).encode(BigInt.one << 9), throwsArgumentError);
      expect(() => UintType().encode(BigInt.from(-1)), throwsArgumentError);
      expect(() => UintType().encode(BigInt.one << 257), throwsArgumentError);
    });

    test("Invalid static byte arrays can't be created", () {
      expect(() => StaticLengthBytes(0), throwsArgumentError);
      expect(() => StaticLengthBytes(33), throwsArgumentError);
      expect(() => StaticLengthBytes(8).encode([0]), throwsArgumentError);
    });
  });
}
