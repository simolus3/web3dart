import 'package:tuple/tuple.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;

class UintType extends ABIType<BigInt> {
  ///The amount of bits stored in this integer. Must be between 1 and 256 and a
  ///multiple of 8.
  final int M;

  @override
  final bool isDynamic = false;
  @override
  String get name => 'uint$M';

  BigInt get maxValue => (BigInt.one << M) - BigInt.one;

  // ignore: avoid_types_as_parameter_names
  UintType({this.M = 256}) {
    if (M <= 0 || M > 256 || M % 8 != 0) {
      throw ArgumentError.value(M, 'M', 'Invalid size argument:');
    }
  }

  @override
  String encode(BigInt data) {
    if (data > maxValue)
      throw ArgumentError('Value to encode must be <= $maxValue, got $data');
    if (data.isNegative)
      throw ArgumentError('Tried to encode negative number as an uint');

    final hex = numbers.toHex(data);

    return ('0' * calculatePadLen(hex.length)) + hex;
  }

  @override
  Tuple2<BigInt, int> decode(String data) =>
      Tuple2(numbers.hexToInt(data.substring(0, 64)), 32);
}

class IntType extends ABIType<BigInt> {
  final int M;

  @override
  final bool isDynamic = false;
  @override
  String get name => 'int$M';

  BigInt get maxValue => (BigInt.one << (M - 1)) - BigInt.one;
  BigInt get minValue => -(BigInt.one << (M - 1));

  // ignore: avoid_types_as_parameter_names
  IntType({this.M = 256}) {
    if (M <= 0 || M > 256 || M % 8 != 0) {
      throw ArgumentError.value(M, 'M', 'Invalid size argument:');
    }
  }

  @override
  String encode(BigInt data) {
    if (data > maxValue || data < minValue)
      throw ArgumentError('Data ($data) must be in [$minValue;$maxValue]');

    if (data.isNegative) {
      //Two's complement of a number (-x) is 2^N - x = 2^N + x for x < 0
      return numbers.toHex((BigInt.one << (ABIType.sizeUnitBytes * 8)) + data);
    } else {
      final encoded = numbers.toHex(data);
      return ('0' * calculatePadLen(encoded.length)) + encoded;
    }
  }

  @override
  Tuple2<BigInt, int> decode(String data) {
    final part = data.substring(0, ABIType.sizeUnitHex);
    final bytes = numbers.hexToBytes(data);
    final isNegative = (bytes[0] & (1 << 7)) == 128; //first bit set?
    var number = BigInt.parse(part, radix: 16);

    if (isNegative) {
      number = (-(BigInt.one << ABIType.sizeUnitBytes * 8)) + number;
    }

    return Tuple2(number, ABIType.sizeUnitBytes);
  }
}

class AddressType extends UintType {
  @override
  final String name = 'address';

  AddressType() : super(M: 160);
}

class BoolType extends ABIType<bool> {
  static final String _encodeTrue = '${'0' * 63}1';
  static final String _encodeFalse = '0' * 64;

  @override
  final String name = 'bool';
  @override
  final bool isDynamic = false;

  @override
  String encode(bool data) => data ? _encodeTrue : _encodeFalse;

  @override
  Tuple2<bool, int> decode(String data) {
    return Tuple2(data[63] == '1', 32);
  }
}
