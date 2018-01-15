import 'package:tuple/tuple.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;

class UintType extends ABIType<int> {

	final int M;

	final bool isDynamic = false;
	String get name => "uint$M";

	UintType({this.M = 256}) {
		if (M <= 0 || M > 256 || M % 8 != 0) {
		  throw new ArgumentError.value("Invalid size argument:", "M", M);
		}
	}

	@override
	String encode(int data) {
		var hex = numbers.toHex(data);

		return ("0" * calculatePadLen(hex.length)) + hex;
	}

  @override
  Tuple2<int, int> decode(String data)
			=> new Tuple2(numbers.hexToInt(data.substring(0, 64)).intValue(), 32);
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