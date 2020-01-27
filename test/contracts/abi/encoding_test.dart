import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

import 'data/basic_abi_tests.dart' as basic;
import 'data/integers.dart' as ints;

import 'utils.dart';

void main() {
  _runTests(basic.content);
  _runTests(ints.content);
}

void _runTests(String content) {
  final parsed = json.decode(content) as Map;

  for (final testCase in parsed.keys) {
    group('ABI - $testCase', () {
      final testVector = parsed[testCase] as Map<String, dynamic>;

      final types = (testVector['types'] as List)
          .cast<String>()
          .map(parseAbiType)
          .toList();
      final tupleWrapper = TupleType(types);
      final result = testVector['result'] as String;
      final input = _mapFromTest(testVector['args']);

      test('encodes', () {
        expectEncodes(tupleWrapper, input, result);
      });

      test('decodes', () {
        expect(tupleWrapper.decode(bufferFromHex(result), 0).data, input);
      });
    });
  }
}

/// Maps types from an Ethereum abi test vector to types that are understood by
/// web3dart:
/// - [int] will be mapped to [BigInt]
/// - a [String] starting with "0x" to [Uint8List]
/// - Strings starting with "@" will be interpreted as [EthereumAddress]
/// - Strings ending with "H" as [BigInt]
dynamic _mapFromTest(dynamic input) {
  if (input is int) return BigInt.from(input);

  if (input is String) {
    if (input.startsWith('0x')) return hexToBytes(input);
    if (input.startsWith('@')) {
      return EthereumAddress.fromHex(input.substring(1));
    }
    if (input.endsWith('H')) {
      return BigInt.parse(input.substring(0, input.length - 1), radix: 16);
    }
    if (input.endsWith('D')) {
      return BigInt.parse(input.substring(0, input.length - 1));
    }
  }

  if (input is List) return input.map(_mapFromTest).toList();

  return input;
}
