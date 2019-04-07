part of 'package:web3dart/contracts.dart';

/// The length of the encoding of a solidity type is always a multiplicative of
/// this unit size.
const int sizeUnitBytes = 32;

/// A type that can be encoded and decoded as specified in the solidity ABI,
/// available at https://solidity.readthedocs.io/en/develop/abi-spec.html
abstract class AbiType<T> {
  const AbiType();

  /// The name of this type, as it would appear in a method signature in the
  /// solidity ABI.
  String get name;

  /// Whether this type is dynamic. A solidity type is dynamic if the length of
  /// its encoding depends on the content (like strings). See
  /// https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
  /// for a formal definition of which types are dynamic.
  bool get isDynamic;

  /// Writes [data] into the [buffer].
  void encode(T data, LengthTrackingByteSink buffer);

  DecodingResult<T> decode(ByteBuffer buffer, int offset);
}

/// Calculates the amount of padding bytes needed so that the length of the
/// padding plus the [bodyLength] is a multiplicative of [sizeUnitBytes].
int calculatePadLength(int bodyLength) {
  assert(bodyLength >= 0);

  if (bodyLength == 0) return sizeUnitBytes;

  final remainder = bodyLength % sizeUnitBytes;
  return remainder == 0 ? 0 : sizeUnitBytes - remainder;
}

class DecodingResult<T> {
  final T data;
  final int bytesRead;

  DecodingResult(this.data, this.bytesRead);

  @override
  String toString() {
    return 'DecodingResult($data, $bytesRead)';
  }

  @override
  int get hashCode => data.hashCode * 31 + bytesRead.hashCode;

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        (other is DecodingResult &&
            other.data == data &&
            other.bytesRead == bytesRead);
  }
}
