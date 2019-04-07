import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/src/utils/length_tracking_byte_sink.dart';
import 'package:web3dart/src/utils/rlp.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('encodes short strings', () {
    final builder = LengthTrackingByteSink();
    encodeString(ascii.encode('dog'), builder);

    expect(builder.asBytes(), [0x83].followedBy(ascii.encode('dog')));
  });

  test('encodes long strings', () {
    final builder = LengthTrackingByteSink();
    final payload = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit';

    encodeString(ascii.encode(payload), builder);

    expect(builder.asBytes(), [0xb8, 0x38].followedBy(ascii.encode(payload)));
  });

  test('encodes empty string', () {
    final builder = LengthTrackingByteSink();
    encodeString(Uint8List(0), builder);
    expect(builder.asBytes(), [0x80]);
  });
}
