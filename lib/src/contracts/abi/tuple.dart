import 'dart:typed_data';

import '../../utils/length_tracking_byte_sink.dart';
import 'integers.dart';
import 'types.dart';

class TupleType extends AbiType<List<dynamic>> {
  /// The types used to encode the individual components of this tuple.
  final List<AbiType> types;

  const TupleType(this.types);

  @override
  String get name {
    final nameBuffer = StringBuffer('(');

    for (var i = 0; i < types.length; i++) {
      if (i != 0) {
        nameBuffer.write(',');
      }
      nameBuffer.write(types[i].name);
    }

    nameBuffer.write(')');
    return nameBuffer.toString();
  }

  @override
  EncodingLengthInfo get encodingLength {
    var trackedLength = 0;

    // tuples are dynamic iff any of their member types is dynamic. Otherwise,
    // it's just all static members concatenated, together.
    for (final type in types) {
      final length = type.encodingLength;
      if (length.isDynamic) return const EncodingLengthInfo.dynamic();

      trackedLength += length.length!;
    }

    return EncodingLengthInfo(trackedLength);
  }

  @override
  void encode(List data, LengthTrackingByteSink buffer) {
    // Formal definition of the encoding: https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
    assert(data.length == types.length);

    // first, encode all non-dynamic values. For each dynamic value we
    // encounter, encode its position instead. Then, encode all the dynamic
    // values.
    var currentDynamicOffset = 0;
    final dynamicHeaderPositions = List.filled(data.length, -1);

    for (var i = 0; i < data.length; i++) {
      final payload = data[i];
      final type = types[i];

      if (type.encodingLength.isDynamic) {
        // just write a bunch of zeroes, we later have to encode the relative
        // offset here.
        dynamicHeaderPositions[i] = buffer.length;
        buffer.add(Uint8List(sizeUnitBytes));

        currentDynamicOffset += sizeUnitBytes;
      } else {
        final lengthBefore = buffer.length;
        type.encode(payload, buffer);

        currentDynamicOffset += buffer.length - lengthBefore;
      }
    }

    // now that the heads are written, write tails for the dynamic values
    for (var i = 0; i < data.length; i++) {
      if (!types[i].encodingLength.isDynamic) continue;

      // replace the 32 zero-bytes with the actual encoded offset
      const UintType().encodeReplace(
          dynamicHeaderPositions[i], BigInt.from(currentDynamicOffset), buffer);

      final lengthBefore = buffer.length;
      types[i].encode(data[i], buffer);
      currentDynamicOffset += buffer.length - lengthBefore;
    }
  }

  @override
  DecodingResult<List> decode(ByteBuffer buffer, int offset) {
    final decoded = [];
    var headersLength = 0;
    var dynamicLength = 0;

    for (final type in types) {
      if (type.encodingLength.isDynamic) {
        final positionResult =
            const UintType().decode(buffer, offset + headersLength);
        headersLength += positionResult.bytesRead;

        final position = positionResult.data.toInt();

        final dataResult = type.decode(buffer, offset + position);
        dynamicLength += dataResult.bytesRead;
        decoded.add(dataResult.data);
      } else {
        final result = type.decode(buffer, offset + headersLength);
        headersLength += result.bytesRead;
        decoded.add(result.data);
      }
    }

    return DecodingResult(decoded, headersLength + dynamicLength);
  }

  @override
  int get hashCode => 37 * types.hashCode;

  @override
  bool operator ==(other) {
    return identical(this, other) || (other is TupleType && _equalTypes(other));
  }

  bool _equalTypes(TupleType o) {
    if (o.types.length != types.length) return false;

    for (var i = 0; i < types.length; i++) {
      if (types[i] != o.types[i]) return false;
    }
    return true;
  }
}
