import 'package:bignum/bignum.dart';
import 'package:tuple/tuple.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;

class UintType extends ABIType<int> {

	final int M;

	final bool isDynamic = false;
	String get name => "uint$M";

	int get maxValue => (1 << M) - 1;

	UintType({this.M = 256}) {
		if (M <= 0 || M > 256 || M % 8 != 0) {
		  throw new ArgumentError.value(M, "M", "Invalid size argument:");
		}
	}

	@override
	String encode(int data) {
		if (data > maxValue)
			throw new ArgumentError("Value to encode must be <= $maxValue, got $data");
		if (data < 0)
			throw new ArgumentError("Tried to encode negative number as an uint");

		var hex = numbers.toHex(data);

		return ("0" * calculatePadLen(hex.length)) + hex;
	}

  @override
  Tuple2<int, int> decode(String data)
			=> new Tuple2(numbers.hexToInt(data.substring(0, 64)).intValue(), 32);
}

class IntType extends ABIType<int> {

	final int M;

	final bool isDynamic = false;
	String get name => "int$M";

	int get maxValue => (1 << (M - 1)) - 1;
	int get minValue => -(1 << (M - 1));

	IntType({this.M = 256}) {
		if (M <= 0 || M > 256 || M % 8 != 0) {
			throw new ArgumentError.value(M, "M", "Invalid size argument:");
		}
	}

	@override
	String encode(int data) {
		if (data > maxValue || data < minValue)
			throw new ArgumentError("Data ($data) must be in [$minValue;$maxValue]");

		if (data < 0) {
			//Two's complement of a number (-x) is 2^N - x = 2^N + x for x < 0
			return numbers.toHex(BigInteger.ONE.shiftLeft(SIZE_UNIT_BYTES * 8) + new BigInteger(data));
		} else {
			var encoded = numbers.toHex(data);
			return ("0" * calculatePadLen(encoded.length)) + encoded;
		}
	}

	@override
	Tuple2<int, int> decode(String data) {
		var part = data.substring(0, SIZE_UNIT_HEX);
		return new Tuple2(new BigInteger.fromBytes(0, numbers.hexToBytes(part)).intValue(), SIZE_UNIT_BYTES);
	}
}

class AddressType extends UintType {

	final String name = "address";

	AddressType() : super(M: 160);

}

class BoolType extends ABIType<bool> {

	static final String _ENCODE_TRUE = ("0" * 63) + "1";
	static final String _ENCODE_FALSE = "0" * 64;

	final String name = "bool";
	final bool isDynamic = false;

	@override
	String encode(bool data) => data ? _ENCODE_TRUE : _ENCODE_FALSE;

  @override
  Tuple2<bool, int> decode(String data) {
    return new Tuple2(data[63] == "1", 32);
  }
}