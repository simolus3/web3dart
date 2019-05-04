part of 'package:web3dart/contracts.dart';

/// The bytes<M> solidity type, which stores up to 32 bytes.
class FixedBytes extends AbiType<Uint8List> {
  /// The amount of bytes to store, between 0 and 32 (both inclusive).
  final int length;

  @override
  String get name => 'bytes$length';

  // the encoding length does not depend on this.length, as it will always be
  // padded to 32 bytes
  @override
  final EncodingLengthInfo encodingLength =
      const EncodingLengthInfo(sizeUnitBytes);

  const FixedBytes(this.length) : assert(0 <= length && length <= 32);

  @override
  void encode(Uint8List data, LengthTrackingByteSink buffer) {
    assert(data.length == length,
        'Invalid length: Tried to encode ${data.length} bytes, but expected exactly $length');
    final paddingBytes = calculatePadLength(length);

    buffer..add(data)..add(Uint8List(paddingBytes));
  }

  @override
  DecodingResult<Uint8List> decode(ByteBuffer buffer, int offset) {
    return DecodingResult(
      buffer.asUint8List(offset, length),
      sizeUnitBytes,
    );
  }
}

class FunctionType extends FixedBytes {
  const FunctionType() : super(24); // 20 bytes for address, 4 for function
}

/// The solidity bytes type, which decodes byte arrays of arbitrary length.
class DynamicBytes extends AbiType<Uint8List> {
  @override
  final String name = 'bytes';

  @override
  final EncodingLengthInfo encodingLength = const EncodingLengthInfo.dynamic();

  const DynamicBytes();

  @override
  void encode(Uint8List data, LengthTrackingByteSink buffer) {
    const UintType().encode(BigInt.from(data.length), buffer);

    final padding = calculatePadLength(data.length);

    buffer..add(data)..add(Uint8List(padding));
  }

  @override
  DecodingResult<Uint8List> decode(ByteBuffer buffer, int offset) {
    final lengthResult = const UintType().decode(buffer, offset);
    final length = lengthResult.data.toInt();
    final padding = calculatePadLength(length);

    // first 32 bytes are taken for the encoded size, read from there
    return DecodingResult(
      buffer.asUint8List(offset + sizeUnitBytes, length),
      sizeUnitBytes + length + padding,
    );
  }
}

/// The solidity string type, which utf-8 encodes strings
class StringType extends AbiType<String> {
  @override
  final String name = 'string';
  @override
  final EncodingLengthInfo encodingLength = const EncodingLengthInfo.dynamic();

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
}

/// The solidity T\[k\] type for arrays whose length is known.
class FixedLengthArray<T> extends AbiType<List<T>> {
  final AbiType<T> type;
  final int length;

  @override
  String get name => '${type.name}[$length]';

  @override
  EncodingLengthInfo get encodingLength {
    if (type.encodingLength.isDynamic)
      return const EncodingLengthInfo.dynamic();
    return EncodingLengthInfo(type.encodingLength.length * length);
  }

  const FixedLengthArray({@required this.type, @required this.length});

  @override
  void encode(List<T> data, LengthTrackingByteSink buffer) {
    assert(data.length == length);

    if (encodingLength.isDynamic) {
      final lengthEncoder = const UintType();

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
      for (var elem in data) {
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
}

/// The solidity T[] type for arrays with an dynamic length.
class DynamicLengthArray<T> extends AbiType<List<T>> {
  final AbiType<T> type;

  @override
  final EncodingLengthInfo encodingLength = const EncodingLengthInfo.dynamic();
  @override
  String get name => '${type.name}[]';

  const DynamicLengthArray({@required this.type});

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
}
