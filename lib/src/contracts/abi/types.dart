import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../utils/length_tracking_byte_sink.dart';
import 'arrays.dart';
import 'integers.dart';
import 'tuple.dart';

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

  /// Information about how long the encoding will be.
  EncodingLengthInfo get encodingLength;

  /// Writes [data] into the [buffer].
  void encode(T data, LengthTrackingByteSink buffer);

  DecodingResult<T> decode(ByteBuffer buffer, int offset);
}

/// Information about whether the length of an encoding depends on the data
/// (dynamic) or is fixed (static). If it's static, also contains information
/// about the length of the encoding.
@immutable
class EncodingLengthInfo {
  /// When this encoding length is not [isDynamic], the length (in bytes) of
  /// an encoded payload. Otherwise null.
  final int? length;

  /// Whether the length of the encoding will depend on the data being encoded.
  ///
  /// Types that have that property are called "dynamic types" in the solidity
  /// abi encoding and are treated differently when being a part of a tuple or
  /// an array.
  bool get isDynamic => length == null;

  const EncodingLengthInfo(this.length);
  const EncodingLengthInfo.dynamic() : length = null;
}

/// Calculates the amount of padding bytes needed so that the length of the
/// padding plus the [bodyLength] is a multiplicative of [sizeUnitBytes]. If
/// [allowEmpty] (defaults to false) is true, an empty length is allowed.
/// Otherwise an empty [bodyLength] will be given a full [sizeUnitBytes]
/// padding.
int calculatePadLength(int bodyLength, {bool allowEmpty = false}) {
  assert(bodyLength >= 0);

  if (bodyLength == 0 && !allowEmpty) return sizeUnitBytes;

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
@internal
final RegExp array = RegExp(r'^(.*)\[(\d*)\]$');
final RegExp _tuple = RegExp(r'^\((.*)\)$');

int _trailingNumber(String str) {
  final match = _trailingDigits.firstMatch(str);
  return int.parse(match!.group(1)!);
}

final _openingParenthesis = '('.codeUnitAt(0);
final _closingParenthesis = ')'.codeUnitAt(0);
final _comma = ','.codeUnitAt(0);

/// Parses an ABI type from its [AbiType.name].
AbiType parseAbiType(String name) {
  if (_easyTypes.containsKey(name)) return _easyTypes[name]!;

  final arrayMatch = array.firstMatch(name);
  if (arrayMatch != null) {
    final type = parseAbiType(arrayMatch.group(1)!);
    final length = arrayMatch.group(2)!;

    if (length.isEmpty) {
      // T[], dynamic length then
      return DynamicLengthArray(type: type);
    } else {
      return FixedLengthArray(type: type, length: int.parse(length));
    }
  }

  final tupleMatch = _tuple.firstMatch(name);
  if (tupleMatch != null) {
    final inner = tupleMatch.group(1)!;
    final types = <AbiType>[];

    // types are separated by a comma. However, we can't just inner.split(')
    // because tuples might be nested: (bool, (uint, string))
    var openParenthesises = 0;
    final typeBuffer = StringBuffer();

    for (final char in inner.codeUnits) {
      if (char == _comma && openParenthesises == 0) {
        types.add(parseAbiType(typeBuffer.toString()));
        typeBuffer.clear();
      } else {
        typeBuffer.writeCharCode(char);

        if (char == _openingParenthesis) {
          openParenthesises++;
        } else if (char == _closingParenthesis) {
          openParenthesises--;
        }
      }
    }

    if (typeBuffer.isNotEmpty) {
      if (openParenthesises != 0) {
        throw ArgumentError(
            'Could not parse abi type because of mismatched brackets: $name');
      }
      types.add(parseAbiType(typeBuffer.toString()));
    }

    return TupleType(types);
  }

  if (name.startsWith('uint')) {
    return UintType(length: _trailingNumber(name))..validate();
  } else if (name.startsWith('int')) {
    return IntType(length: _trailingNumber(name))..validate();
  } else if (name.startsWith('bytes')) {
    return FixedBytes(_trailingNumber(name))..validate();
  }

  throw ArgumentError('Could not parse abi type with name: $name');
}
