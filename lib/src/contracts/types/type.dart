import "package:tuple/tuple.dart";

abstract class ABIType<T> {

	final int SIZE_UNIT_BYTES = 32;
	final int SIZE_UNIT_HEX = 64;

	String get name;
	bool get isDynamic;

	///Encode as hex string that is not prefixed with 0x
	String encode(T data);

	/// Decode the value and return the size (in bytes) that were read from data
	/// in order to do so.
	Tuple2<T, int> decode(String data);

	int calculatePadLen(int actualLength) {
		//must be padded with x so that actualLength + x = k * SIZE_UNIT_HEX
		var mod = actualLength % SIZE_UNIT_HEX;
		return mod == 0 && actualLength > 0 ? 0 : SIZE_UNIT_HEX - mod;
	}

	@override int get hashCode;
	@override operator ==(other);

	Tuple3<T, String, int> decodeRest(String input) {
		var data = decode(input);

		return new Tuple3(data.item1, input.substring(data.item2 * 2), data.item2);
	}
}

/*
TO-DO List for types:

name					can encode		can decode
uint<M>				yes						yes
int<M>				yes						yes
address				yes						yes
bool					yes						yes
fixed					no						no
ufixed				no						no
bytes<M>			yes						yes
function			yes						yes
<type>[k]			yes						yes
bytes					yes						yes
string				yes						yes
<type>[]			yes						yes
tuple					no						no
 */
