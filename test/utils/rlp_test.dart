import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/utils/rlp.dart';
import 'package:test/test.dart';

void main() {
  final file = File(join('test', 'utils', 'rlp_test_vectors.json'));
  final testContent = json.decode(file.readAsStringSync()) as Map;

  for (var key in testContent.keys) {
    test('$key', () {
      final data = testContent[key];
      final input = _mapTestData(data['in']);
      final output = data['out'] as String;

      expect(bytesToHex(encode(input), include0x: true), output);
    });
  }
}

dynamic _mapTestData(dynamic data) {
  if (data is String && data.startsWith('#')) {
    return BigInt.parse(data.substring(1));
  }

  return data;
}
