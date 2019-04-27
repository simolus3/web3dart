part of 'package:web3dart/contracts.dart';

abstract class _IntTypeBase extends AbiType<BigInt> {
  /// The length of this uint, int bits. Must be a multiple of 8.
  final int length;

  @override
  final EncodingLengthInfo encodingLength =
      const EncodingLengthInfo(sizeUnitBytes);

  String get _namePrefix;
  @override
  String get name => _namePrefix + length.toString();

  const _IntTypeBase(this.length)
      : assert(length % 8 == 0),
        assert(0 < length && length <= 256);

  @override
  DecodingResult<BigInt> decode(ByteBuffer buffer, int offset) {
    // we're always going to read a 32-byte block for integers
    return DecodingResult(
        _decode32Bytes(buffer.asUint8List(offset, sizeUnitBytes)),
        sizeUnitBytes);
  }

  BigInt _decode32Bytes(Uint8List data);
}

/// The solidity uint<M> type that encodes unsigned integers.
class UintType extends _IntTypeBase {
  @override
  final String _namePrefix = 'uint';

  const UintType({int length = 256}) : super(length);

  @override
  void encode(BigInt data, LengthTrackingByteSink buffer) {
    assert(data < BigInt.one << length);
    assert(!data.isNegative);

    final bytes = intToBytes(data);
    final padLen = calculatePadLength(bytes.length);
    buffer
      ..add(Uint8List(padLen)) // will be filled with 0
      ..add(bytes);
  }

  void encodeReplace(
      int startIndex, BigInt data, LengthTrackingByteSink buffer) {
    final bytes = intToBytes(data);
    final padLen = calculatePadLength(bytes.length);

    buffer
      ..setRange(startIndex, startIndex + padLen, Uint8List(padLen))
      ..setRange(startIndex + padLen, startIndex + sizeUnitBytes, bytes);
  }

  @override
  BigInt _decode32Bytes(Uint8List data) {
    // The padded zeroes won't make a difference when parsing so we can ignore
    // them.
    return bytesToInt(data);
  }
}

/// Solidity address type
class AddressType extends AbiType<EthereumAddress> {
  const AddressType();

  static const _paddingLen = sizeUnitBytes - EthereumAddress.addressByteLength;

  @override
  final EncodingLengthInfo encodingLength =
      const EncodingLengthInfo(sizeUnitBytes);

  @override
  final String name = 'address';

  @override
  void encode(EthereumAddress data, LengthTrackingByteSink buffer) {
    buffer..add(Uint8List(_paddingLen))..add(data.addressBytes);
  }

  @override
  DecodingResult<EthereumAddress> decode(ByteBuffer buffer, int offset) {
    final addressBytes = buffer.asUint8List(
        offset + _paddingLen, EthereumAddress.addressByteLength);
    return DecodingResult(EthereumAddress(addressBytes), sizeUnitBytes);
  }
}

/// Solidity bool type
class BoolType extends AbiType<bool> {
  static final Uint8List _false = Uint8List(sizeUnitBytes);
  static final Uint8List _true = Uint8List(sizeUnitBytes)
    ..[sizeUnitBytes - 1] = 1;

  const BoolType();

  @override
  final EncodingLengthInfo encodingLength =
      const EncodingLengthInfo(sizeUnitBytes);

  @override
  final String name = 'bool';

  @override
  void encode(bool data, LengthTrackingByteSink buffer) {
    buffer.add(data ? _true : _false);
  }

  @override
  DecodingResult<bool> decode(ByteBuffer buffer, int offset) {
    final decoded = buffer.asUint8List(offset, sizeUnitBytes);
    final value = (decoded[sizeUnitBytes - 1] & 1) == 1;

    return DecodingResult(value, sizeUnitBytes);
  }
}

/// The solidity int<M> types that encodes twos-complement integers.
class IntType extends _IntTypeBase {
  @override
  final String _namePrefix = 'int';

  const IntType({int length = 256}) : super(length);

  @override
  void encode(BigInt data, LengthTrackingByteSink buffer) {
    final negative = data.isNegative;
    Uint8List bytesData;

    if (negative) {
      // twos complement
      bytesData = intToBytes((BigInt.one << length) + data);
    } else {
      bytesData = intToBytes(data);
    }

    final padLen = calculatePadLength(bytesData.length);

    // signed expansion: use 0b11111111 when negative, 0 otherwise
    if (negative) {
      buffer.add(List.filled(padLen, 0xFF));
    } else {
      buffer.add(Uint8List(padLen)); // will be filled with zeroes
    }

    buffer.add(bytesData);
  }

  @override
  BigInt _decode32Bytes(Uint8List data) {
    final negative = data[0] >= 128; // first bit set?
    final parsedAsUnsigned = bytesToInt(data);

    return negative
        ? (-(BigInt.one << length) + parsedAsUnsigned)
        : parsedAsUnsigned;
  }
}
