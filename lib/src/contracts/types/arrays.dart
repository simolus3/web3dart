import "dart:convert";

import 'package:tuple/tuple.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;

class DynamicLengthArrayType<T> extends ABIType<List<T>> {

	final ABIType<T> type;

  final bool isDynamic = true;

  DynamicLengthArrayType(this.type);

	@override
	String get name => "${type.name}[]";

  @override
  String encode(List<T> data) {
		int size = data.length;

		var sizeEncoded = new UintType().encode(size);
		var dataEncoded = new StaticLengthArrayType(type, size).encode(data);
		return sizeEncoded + dataEncoded;
  }

  @override
  Tuple2<List<T>, int> decode(String data) {
    var decodedLength = new UintType().decodeRest(data);

    var length = decodedLength.item1;
    data = decodedLength.item2;

    var decoded = new StaticLengthArrayType(type, length).decode(data);
    return new Tuple2(decoded.item1, decoded.item2 + decodedLength.item3);
  }
}

class StaticLengthArrayType<T> extends ABIType<List<T>> {

	final ABIType<T> type;
	final int length;

	bool get isDynamic => type.isDynamic && length > 0;
	String get name => "${type.name}[$length]";

	StaticLengthArrayType(this.type, this.length);

  @override
  String encode(List<T> data) {
  	StringBuffer buffer = new StringBuffer();

  	for (var element in data) {
  		buffer.write(type.encode(element));
		}

		return buffer.toString();
  }
  @override
  Tuple2<List<T>, int> decode(String data) {
  	var list = new List<T>();
  	var totalLength = 0;
  	
    for (int i = 0; i < length; i++) {
    	var decodedPart = type.decodeRest(data);

    	list.add(decodedPart.item1);
    	data = decodedPart.item2;
			totalLength += decodedPart.item3;
		}
		
		return new Tuple2(list, totalLength);
  }
}

class StaticLengthBytes extends ABIType<List<int>> {

	final int length;

	final bool isDynamic = false;
	String get name => "bytes$length";

	StaticLengthBytes(this.length);

	@override
	String encode(List<int> bytes) {
		var encoded = numbers.bytesToHex(bytes);

		return encoded + ("0" * (calculatePadLen(encoded.length)));
	}

  @override
  Tuple2<List<int>, int> decode(String data) {
    var encodedLength = (calculatePadLen(length * 2) + length * 2) ~/ 2;

    data = data.substring(0, length * 2); //rest is right-padded with 0
    var bytes = numbers.hexToBytes(data);
    return new Tuple2(bytes, encodedLength);
  }
}

class DynamicLengthBytes extends ABIType<List<int>> {

	final bool isDynamic = true;
	final String name = "bytes";

	@override
	String encode(List<int> bytes) {
		var length = bytes.length;

		var dataEncoded = new StaticLengthBytes(length).encode(bytes);
		return new UintType().encode(length) + dataEncoded;
	}

  @override
  Tuple2<List<int>, int> decode(String data) {
		var decodedLength = new UintType().decodeRest(data);

		var length = decodedLength.item1;
		data = decodedLength.item2;

		var decodedBytes = new StaticLengthBytes(length).decode(data);
		return new Tuple2(decodedBytes.item1, decodedBytes.item2 + decodedLength.item3);
  }
}

class StringType extends ABIType<String> {

	final bool isDynamic = true;
	final String name = "string";

	@override
	String encode(String data) {
		return new DynamicLengthBytes().encode(UTF8.encode(data));
	}

  @override
  Tuple2<String, int> decode(String data) {
    var decodedBytes = new DynamicLengthBytes().decode(data);
    return new Tuple2(UTF8.decode(decodedBytes.item1), decodedBytes.item2);
  }
}

class FunctionType extends StaticLengthBytes {

	final String name = "function";

  FunctionType() : super(24); //20 for address, 4 for identifier

}