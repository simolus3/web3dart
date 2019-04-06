import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:web3dart/crypto.dart';

@visibleForTesting
class LengthTrackingByteSink extends ByteConversionSinkBase {

  final Uint8Buffer _buffer = Uint8Buffer();
  int _length = 0;

  int get length => _length;

  Uint8List asBytes() {
    return _buffer.buffer.asUint8List(0, _length);
  }

  @override
  void add(List<int> chunk) {
    _buffer.addAll(chunk);
    _length += chunk.length;
  }

  void addByte(int byte) {
    _buffer.add(byte);
    _length++;
  }

  @override
  void close() {
    // no-op, never used
  }

}

void encodeString(Uint8List string, LengthTrackingByteSink builder) {
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
    encodeString(Uint8List(0), builder);
  } else {
    encodeString(intToBytes(val), builder);
  }
}

void _encodeToBuffer(dynamic value, LengthTrackingByteSink builder) {
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
  final builder = LengthTrackingByteSink();
  _encodeToBuffer(value, builder);

  return builder.asBytes();
}
