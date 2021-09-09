import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../utils/length_tracking_byte_sink.dart';
import '../../utils/typed_data.dart';
import 'integers.dart';
import 'types.dart';

/// The bytes<M> solidity type, which stores up to 32 bytes.
class FixedBytes extends AbiType<Uint8List> {
  /// The amount of bytes to store, between 0 and 32 (both inclusive).
  final int length;

  @override
  String get name => 'bytes$length';

  // the encoding length does not depend on this.length, as it will always be
  // padded to 32 bytes
  @override
  EncodingLengthInfo get encodingLength =>
      const EncodingLengthInfo(sizeUnitBytes);

  const FixedBytes(this.length) : assert(0 <= length && length <= 32);

  @internal
  void validate() {
    if (length < 0 || length > 32) {
      throw Exception('Invalid length for bytes: was $length');
    }
  }

  @override
  void encode(Uint8List data, LengthTrackingByteSink buffer) {
    assert(data.length == length,
        'Invalid length: Tried to encode ${data.length} bytes, but expected exactly $length');
    final paddingBytes = calculatePadLength(length);

    buffer
      ..add(data)
      ..add(Uint8List(paddingBytes));
  }

  @override
  DecodingResult<Uint8List> decode(ByteBuffer buffer, int offset) {
    return DecodingResult(
      buffer.asUint8List(offset, length),
      sizeUnitBytes,
    );
  }

  @override
  int get hashCode => 29 * length;

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        (other is FixedBytes && other.length == length);
  }
}

class FunctionType extends FixedBytes {
  // 20 bytes for address, 4 for function name
  const FunctionType() : super(24);

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(other) {
    return other.runtimeType == FunctionType;
  }
}

/// The solidity bytes type, which decodes byte arrays of arbitrary length.
class DynamicBytes extends AbiType<Uint8List> {
  @override
  String get name => 'bytes';

  @override
  EncodingLengthInfo get encodingLength => const EncodingLengthInfo.dynamic();

  const DynamicBytes();

  @override
  void encode(Uint8List data, LengthTrackingByteSink buffer) {
    const UintType().encode(BigInt.from(data.length), buffer);

    final padding = calculatePadLength(data.length, allowEmpty: true);

    buffer
      ..add(data)
      ..add(Uint8List(padding));
  }

  @override
  DecodingResult<Uint8List> decode(ByteBuffer buffer, int offset) {
    final lengthResult = const UintType().decode(buffer, offset);
    final length = lengthResult.data.toInt();
    final padding = calculatePadLength(length, allowEmpty: true);

    // first 32 bytes are taken for the encoded size, read from there
    return DecodingResult(
      buffer.asUint8List(offset + sizeUnitBytes, length),
      sizeUnitBytes + length + padding,
    );
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(other) {
    return other.runtimeType == DynamicBytes;
  }
}

/// The solidity string type, which utf-8 encodes strings
class StringType extends AbiType<String> {
  @override
  String get name => 'string';
  @override
  EncodingLengthInfo get encodingLength => const EncodingLengthInfo.dynamic();

  const StringType();

  @override
  void encode(String data, LengthTrackingByteSink buffer) {
    const DynamicBytes().encode(uint8ListFromList(utf8.encode(data)), buffer);
  }

  @override
  DecodingResult<String> decode(ByteBuffer buffer, int offset) {
    final bytesResult = const DynamicBytes().decode(buffer, offset);

    return DecodingResult(utf8.decode(bytesResult.data), bytesResult.bytesRead);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(other) {
    return other.runtimeType == StringType;
  }
}

/// Base class for (non-byte) arrays in solidity.
abstract class BaseArrayType<T> extends AbiType<List<T>> {
  /// The inner abi type.
  final AbiType<T> type;

  const BaseArrayType._(this.type);
}

/// The solidity T\[k\] type for arrays whose length is known.
class FixedLengthArray<T> extends BaseArrayType<T> {
  final int length;

  @override
  String get name => '${type.name}[$length]';

  @override
  EncodingLengthInfo get encodingLength {
    if (type.encodingLength.isDynamic) {
      return const EncodingLengthInfo.dynamic();
    }
    return EncodingLengthInfo(type.encodingLength.length! * length);
  }

  const FixedLengthArray({required AbiType<T> type, required this.length})
      : super._(type);

  @override
  void encode(List<T> data, LengthTrackingByteSink buffer) {
    assert(data.length == length);

    if (encodingLength.isDynamic) {
      const lengthEncoder = UintType();

      final startPosition = buffer.length;
      var currentOffset = data.length * sizeUnitBytes;

      // first, write a bunch of zeroes were the length will be written later.
      buffer.add(Uint8List(data.length * sizeUnitBytes));

      for (var i = 0; i < length; i++) {
        // write the actual position into the slot reserved earlier
        lengthEncoder.encodeReplace(startPosition + i * sizeUnitBytes,
            BigInt.from(currentOffset), buffer);

        final lengthBefore = buffer.length;
        type.encode(data[i], buffer);
        currentOffset += buffer.length - lengthBefore;
      }
    } else {
      for (final elem in data) {
        type.encode(elem, buffer);
      }
    }
  }

  @override
  DecodingResult<List<T>> decode(ByteBuffer buffer, int offset) {
    final decoded = <T>[];
    var headersLength = 0;
    var dynamicLength = 0;

    if (encodingLength.isDynamic) {
      for (var i = 0; i < length; i++) {
        final positionResult =
            const UintType().decode(buffer, offset + headersLength);
        headersLength += positionResult.bytesRead;

        final position = positionResult.data.toInt();

        final dataResult = type.decode(buffer, offset + position);
        dynamicLength += dataResult.bytesRead;
        decoded.add(dataResult.data);
      }
    } else {
      for (var i = 0; i < length; i++) {
        final result = type.decode(buffer, offset + headersLength);
        headersLength += result.bytesRead;

        decoded.add(result.data);
      }
    }

    return DecodingResult(decoded, headersLength + dynamicLength);
  }

  @override
  int get hashCode => 41 * length + 5 * type.hashCode;

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        (other is FixedLengthArray &&
            other.length == length &&
            other.type == type);
  }
}

/// The solidity T[] type for arrays with an dynamic length.
class DynamicLengthArray<T> extends BaseArrayType<T> {
  @override
  EncodingLengthInfo get encodingLength => const EncodingLengthInfo.dynamic();
  @override
  String get name => '${type.name}[]';

  const DynamicLengthArray({required AbiType<T> type}) : super._(type);

  @override
  void encode(List<T> data, LengthTrackingByteSink buffer) {
    const UintType().encode(BigInt.from(data.length), buffer);
    FixedLengthArray(type: type, length: data.length).encode(data, buffer);
  }

  @override
  DecodingResult<List<T>> decode(ByteBuffer buffer, int offset) {
    final lengthResult = const UintType().decode(buffer, offset);

    final arrayType =
        FixedLengthArray<T>(type: type, length: lengthResult.data.toInt());
    final dataResult =
        arrayType.decode(buffer, offset + lengthResult.bytesRead);

    return DecodingResult(
        dataResult.data, lengthResult.bytesRead + dataResult.bytesRead);
  }

  @override
  int get hashCode => 31 * type.hashCode;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is DynamicLengthArray && other.type == type);
  }
}
