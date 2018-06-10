import "dart:convert" show utf8;

import 'package:tuple/tuple.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;

class DynamicLengthArrayType<T> extends ABIType<List<T>> {

	final ABIType<T> type;

  @override
  final bool isDynamic = true;

  DynamicLengthArrayType(this.type);

	@override
	String get name => "${type.name}[]";

  @override
  String encode(List<T> data) {
		var size = data.length;

		var sizeEncoded = new UintType().encode(new BigInt.from(size));
		var dataEncoded = new StaticLengthArrayType(type, size).encode(data);
		return sizeEncoded + dataEncoded;
  }

  @override
  Tuple2<List<T>, int> decode(String data) {
    var decodedLength = new UintType().decodeRest(data);

    var length = decodedLength.item1.toInt();

    var decoded = new StaticLengthArrayType(type, length).decode(decodedLength.item2);
    return new Tuple2(decoded.item1, decoded.item2 + decodedLength.item3);
  }
}

class StaticLengthArrayType<T> extends ABIType<List<T>> {

	final ABIType<T> type;
	final int length;

	@override
  bool get isDynamic => type.isDynamic && length > 0;
	@override
  String get name => "${type.name}[$length]";

	StaticLengthArrayType(this.type, this.length);

  @override
  String encode(List<T> data) {
  	var buffer = new StringBuffer();

  	for (var element in data) {
  		buffer.write(type.encode(element));
		}

		return buffer.toString();
  }
  @override
  Tuple2<List<T>, int> decode(String data) {
  	var list = <T>[];
  	var totalLength = 0;
  	
    var modifiedData = data;
    for (var i = 0; i < length; i++) {
    	var decodedPart = type.decodeRest(modifiedData);

    	list.add(decodedPart.item1);
    	modifiedData = decodedPart.item2;
			totalLength += decodedPart.item3;
		}
		
		return new Tuple2(list, totalLength);
  }
}

class StaticLengthBytes extends ABIType<List<int>> {

	final int length;

	@override
  final bool isDynamic = false;
	@override
  String get name => "bytes$length";

	StaticLengthBytes(this.length, {bool ignoreLength = false}) {
		if (!ignoreLength && (length <= 0 || length > 32))
			throw new ArgumentError("Length of static byte array must be between 0 and 32, was $length");
	}

	@override
	String encode(List<int> data) {
		if (data.length != length)
			throw new ArgumentError("Length of bytes did not match. (Expected $length, got ${data.length})");
		var encoded = numbers.bytesToHex(data);

		return encoded + ("0" * (calculatePadLen(encoded.length)));
	}

  @override
  Tuple2<List<int>, int> decode(String data) {
    var encodedLength = (calculatePadLen(length * 2) + length * 2) ~/ 2;

    var modifiedData = data.substring(0, length * 2); //rest is right-padded with 0
    var bytes = numbers.hexToBytes(modifiedData);
    return new Tuple2(bytes, encodedLength);
  }
}

class DynamicLengthBytes extends ABIType<List<int>> {

	@override
  final bool isDynamic = true;
	@override
  final String name = "bytes";

	@override
	String encode(List<int> bytes) {
		var length = bytes.length;

		var dataEncoded = new StaticLengthBytes(length, ignoreLength: true).encode(bytes);
		return new UintType().encode(new BigInt.from(length)) + dataEncoded;
	}

  @override
  Tuple2<List<int>, int> decode(String data) {
		var decodedLength = new UintType().decodeRest(data);

		var length = decodedLength.item1.toInt();
		data = decodedLength.item2;

		var decodedBytes = new StaticLengthBytes(length, ignoreLength: true).decode(data);
		return new Tuple2(decodedBytes.item1, decodedBytes.item2 + decodedLength.item3);
  }
}

class StringType extends ABIType<String> {

	final bool isDynamic = true;
	final String name = "string";

	@override
	String encode(String data) {
		return new DynamicLengthBytes().encode(utf8.encode(data));
	}

  @override
  Tuple2<String, int> decode(String data) {
    var decodedBytes = new DynamicLengthBytes().decode(data);
    return new Tuple2(utf8.decode(decodedBytes.item1), decodedBytes.item2);
  }
}

class FunctionType extends StaticLengthBytes {

	final String name = "function";

  FunctionType() : super(24); //20 for address, 4 for identifier

}