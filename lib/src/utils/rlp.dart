import 'dart:io';
import 'dart:typed_data';

import 'package:web3dart/crypto.dart';

// todo don't depend on dart:io

void encodeString(Uint8List string, BytesBuilder builder) {
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

void encodeList(List list, BytesBuilder builder) {
  final subBuilder = BytesBuilder();
  for (var item in list) {
    _encodeToBuffer(item, subBuilder);
  }

  final length = subBuilder.length;
  if (length <= 55) {
    builder
      ..addByte(0xc0 + length)
      ..add(subBuilder.takeBytes());
    return;
  } else {
    final encodedLength = intToBytes(BigInt.from(length));

    builder
      ..addByte(0xf7 + encodedLength.length)
      ..add(encodedLength)
      ..add(subBuilder.takeBytes());
    return;
  }
}

void _encodeInt(BigInt val, BytesBuilder builder) {
  if (val == BigInt.zero) {
    encodeString(Uint8List(0), builder);
  } else {
    encodeString(intToBytes(val), builder);
  }
}

void _encodeToBuffer(dynamic value, BytesBuilder builder) {
  if (value is Uint8List) {
    encodeString(value, builder);
  } else if (value is List) {
    encodeList(value, builder);
  } else if (value is BigInt) {
    _encodeInt(value, builder);
  } else if (value is int) {
    _encodeInt(BigInt.from(value), builder);
  } else {
    throw UnsupportedError('$value cannot be rlp-encoded');
  }
}

List<int> encode(dynamic value) {
  final builder = BytesBuilder();
  _encodeToBuffer(value, builder);
  return builder.takeBytes();
}
