import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web3dart/src/utils/rlp.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('encodes short strings', () {
    final builder = BytesBuilder();
    encodeString(ascii.encode('dog'), builder);

    expect(builder.toBytes(), [0x83].followedBy(ascii.encode('dog')));
  });

  test('encodes long strings', () {
    final builder = BytesBuilder();
    final payload = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit';

    encodeString(ascii.encode(payload), builder);

    expect(builder.toBytes(), [0xb8, 0x38].followedBy(ascii.encode(payload)));
  });

  test('encodes empty string', () {
    final builder = BytesBuilder();
    encodeString(Uint8List(0), builder);
    expect(builder.takeBytes(), [0x80]);
  });
}