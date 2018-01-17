import 'dart:convert';

import 'package:test/test.dart';
import 'package:web3dart/src/contracts/types/arrays.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/src/contracts/types/type.dart';

const Map<bool, String> _BOOL_ENCODED = const {
	false: "0000000000000000000000000000000000000000000000000000000000000000",
	true: "0000000000000000000000000000000000000000000000000000000000000001",
};

const Map<int, String> _UINT_ENCODED = const {
	0: "0000000000000000000000000000000000000000000000000000000000000000",
	9223372036854775807: "0000000000000000000000000000000000000000000000007fffffffffffffff",
	0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff: "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
};

const Map<int, String> _INT_ENCODED = const {
	0: "0000000000000000000000000000000000000000000000000000000000000000",
	9223372036854775807: "0000000000000000000000000000000000000000000000007fffffffffffffff",
	-9223372036854775808: "ffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000",
	-1: "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
};

void testEncode<T>(ABIType<T> type, Map<T, String> data) {
	data.forEach((value, encoded) {
		expect(type.encode(value), equals(encoded));
	});
}

void testDecode<T>(ABIType<T> type, Map<T, String> data) {
	data.forEach((value, encoded) {
		expect(type.decode(encoded).item1, equals(value));
	});
}

void main() {
	group("Utils", () {
		test("Padding", () {
			var type = new BoolType();

			expect(type.calculatePadLen(2), equals(62));
			expect(type.calculatePadLen(131), equals(61));
			expect(type.calculatePadLen(0), equals(64));
			expect(type.calculatePadLen(128), equals(0));
		});
	});

	var boolType = new BoolType();
	var uint256Type = new UintType();
	var int256Type = new IntType();

	group("Encode", () {
		test("bools", () {
			testEncode(boolType, _BOOL_ENCODED);
		});

		test("uints", () {
			testEncode(uint256Type, _UINT_ENCODED);
		});

		test("ints", () {
			testEncode(int256Type, _INT_ENCODED);
		});

		test("static bytes", () {
			expect(new StaticLengthBytes(6).encode([0, 1, 2, 3, 4, 5]),
					equals("0001020304050000000000000000000000000000000000000000000000000000"));
			expect(new StaticLengthBytes(1).encode([0]), equals("0" * 64));
			expect(new StaticLengthBytes(4).encode(UTF8.encode("dave")), equals("6461766500000000000000000000000000000000000000000000000000000000"));
		});
	});

	group("Decode", () {
		test("bools", () {
			testDecode(boolType, _BOOL_ENCODED);
		});

		test("uints", () {
			testDecode(uint256Type, _UINT_ENCODED);
		});

		test("ints", () {
			testDecode(int256Type, _INT_ENCODED);
		});
	});

	group("Parameter validation", () {
		test("Invalid uints can't be created", () {
			expect(() => new UintType(M: 54), throwsArgumentError); //not divisible by 8
			expect(() => new UintType(M: 0), throwsArgumentError);
			expect(() => new UintType(M: 1024), throwsArgumentError);
			expect(() => new UintType(M: -8), throwsArgumentError);

			expect(() => new UintType(M: 8).encode(1 << 9), throwsArgumentError);
			expect(() => new UintType().encode(-1), throwsArgumentError);
			expect(() => new UintType().encode(1 << 257), throwsArgumentError);
		});

		test("Invalid static byte arrays can't be created", () {
			expect(() => new StaticLengthBytes(0), throwsArgumentError);
			expect(() => new StaticLengthBytes(33), throwsArgumentError);
			expect(() => new StaticLengthBytes(8).encode([0]), throwsArgumentError);
		});
	});
}