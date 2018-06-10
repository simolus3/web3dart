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
  String get name => "uint$M";

	BigInt get maxValue => (BigInt.one << M) - BigInt.one;

	UintType({this.M = 256}) {
		if (M <= 0 || M > 256 || M % 8 != 0) {
		  throw new ArgumentError.value(M, "M", "Invalid size argument:");
		}
	}

	@override
	String encode(BigInt data) {
		if (data > maxValue)
			throw new ArgumentError("Value to encode must be <= $maxValue, got $data");
		if (data.isNegative)
			throw new ArgumentError("Tried to encode negative number as an uint");

		var hex = numbers.toHex(data);

		return ("0" * calculatePadLen(hex.length)) + hex;
	}

  @override
  Tuple2<BigInt, int> decode(String data)
			=> new Tuple2(numbers.hexToInt(data.substring(0, 64)), 32);
}

class IntType extends ABIType<BigInt> {

	final int M;

	@override
  final bool isDynamic = false;
	@override
  String get name => "int$M";

	BigInt get maxValue => (BigInt.one << (M - 1)) - BigInt.one;
	BigInt get minValue => -(BigInt.one << (M - 1));

	IntType({this.M = 256}) {
		if (M <= 0 || M > 256 || M % 8 != 0) {
			throw new ArgumentError.value(M, "M", "Invalid size argument:");
		}
	}

	@override
	String encode(BigInt data) {
		if (data > maxValue || data < minValue)
			throw new ArgumentError("Data ($data) must be in [$minValue;$maxValue]");

		if (data.isNegative) {
			//Two's complement of a number (-x) is 2^N - x = 2^N + x for x < 0
			return numbers.toHex((BigInt.one << (SIZE_UNIT_BYTES * 8)) + data);
		} else {
			var encoded = numbers.toHex(data);
			return ("0" * calculatePadLen(encoded.length)) + encoded;
		}
	}

	@override
	Tuple2<BigInt, int> decode(String data) {
		var part = data.substring(0, SIZE_UNIT_HEX);
    var bytes = numbers.hexToBytes(data);
    var isNegative = (bytes[0] & (1 << 7)) == 128; //first bit set?
    var number = BigInt.parse(part, radix: 16);

    if (isNegative) {
      number = (-(BigInt.one << SIZE_UNIT_BYTES * 8)) + number;
    }

		return new Tuple2(number, SIZE_UNIT_BYTES);
	}
}

class AddressType extends UintType {

	@override
  final String name = "address";

	AddressType() : super(M: 160);

}

class BoolType extends ABIType<bool> {

	static final String _encodeTrue = ("0" * 63) + "1";
	static final String _encodeFalse = "0" * 64;

	@override
  final String name = "bool";
	@override
  final bool isDynamic = false;

	@override
	String encode(bool data) => data ? _encodeTrue : _encodeFalse;

  @override
  Tuple2<bool, int> decode(String data) {
    return new Tuple2(data[63] == "1", 32);
  }
}