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

// some ABI types that are easy to construct because they have a fixed name
const Map<String, AbiType> _easyTypes = {
  'uint': UintType(),
  'int': IntType(),
  'address': AddressType(),
  'bool': BoolType(),
  'function': FunctionType(),
  'bytes': DynamicBytes(),
  'string': StringType(),
};

final RegExp _trailingDigits = RegExp(r'^(?:\D|\d)*\D(\d*)$');
final RegExp _array = RegExp(r'^(.*)\[(\d*)\]$');
final RegExp _tuple = RegExp(r'^\((.*)\)$');

int _trailingNumber(String str) {
  final match = _trailingDigits.firstMatch(str);
  return int.parse(match.group(1));
}

/// Parses an ABI type from its [AbiType.name].
@visibleForTesting
AbiType parseAbiType(String name) {
  if (_easyTypes.containsKey(name))
    return _easyTypes[name];
  
  final arrayMatch = _array.firstMatch(name);
  if (arrayMatch != null) {
    final type = parseAbiType(arrayMatch.group(1));
    final length = arrayMatch.group(2);

    if (length.isEmpty) { // T[], dynamic length then
      return DynamicLengthArray(type: type);
    } else {
      return FixedLengthArray(type: type, length: int.parse(length));
    }
  }

  final tupleMatch = _tuple.firstMatch(name);
  if (tupleMatch != null) {
    final inner = tupleMatch.group(1);
    final types = <AbiType>[];

    for (var typeDesc in inner.split(',')) {
      types.add(parseAbiType(typeDesc));
    }

    return TupleType(types);
  }

  if (name.startsWith('uint')) {
    return UintType(length: _trailingNumber(name));
  } else if (name.startsWith('int')) {
    return IntType(length: _trailingNumber(name));
  } else if (name.startsWith('bytes')) {
    return FixedBytes(_trailingNumber(name));
  }

  throw ArgumentError('Could not parse abi type with name: $name');
}
