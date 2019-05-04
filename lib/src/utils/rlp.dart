import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/utils/length_tracking_byte_sink.dart';
import 'package:web3dart/src/utils/typed_data.dart';

void _encodeString(Uint8List string, LengthTrackingByteSink builder) {
  // For a single byte in [0x00, 0x7f], that byte is its own RLP encoding
  if (string.length == 1 && string[0] <= 0x7f) {
    builder.addByte(string[0]);
    return;
  }

  // If a string is between 0 and 55 bytes long, its encoding is 0x80 plus
  // its length, followed by the actual string
  if (string.length <= 55) {
    builder
      ..addByte(0x80 + string.length)
      ..add(string);
    return;
  }

  // More than 55 bytes long, RLP is (0xb7 + length of encoded length), followed
  // by the length, followed by the actual string
  final length = string.length;
  final encodedLength = intToBytes(BigInt.from(length));

  builder
    ..addByte(0xb7 + encodedLength.length)
    ..add(encodedLength)
    ..add(string);
}

void encodeList(List list, LengthTrackingByteSink builder) {
  final subBuilder = LengthTrackingByteSink();
  for (var item in list) {
    _encodeToBuffer(item, subBuilder);
  }

  final length = subBuilder.length;
  if (length <= 55) {
    builder
      ..addByte(0xc0 + length)
      ..add(subBuilder.asBytes());
    return;
  } else {
    final encodedLength = intToBytes(BigInt.from(length));

    builder
      ..addByte(0xf7 + encodedLength.length)
      ..add(encodedLength)
      ..add(subBuilder.asBytes());
    return;
  }
}

void _encodeInt(BigInt val, LengthTrackingByteSink builder) {
  if (val == BigInt.zero) {
    _encodeString(Uint8List(0), builder);
  } else {
    _encodeString(intToBytes(val), builder);
  }
}

void _encodeToBuffer(dynamic value, LengthTrackingByteSink builder) {
  if (value is Uint8List) {
    _encodeString(value, builder);
  } else if (value is List) {
    encodeList(value, builder);
  } else if (value is BigInt) {
    _encodeInt(value, builder);
  } else if (value is int) {
    _encodeInt(BigInt.from(value), builder);
  } else if (value is String) {
    _encodeString(uint8ListFromList(utf8.encode(value)), builder);
  } else {
    throw UnsupportedError('$value cannot be rlp-encoded');
  }
}

List<int> encode(dynamic value) {
  final builder = LengthTrackingByteSink();
  _encodeToBuffer(value, builder);

  return builder.asBytes();
}
