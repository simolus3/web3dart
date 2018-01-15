import 'dart:convert';

import 'package:test/test.dart';
import 'package:web3dart/src/contracts/types/arrays.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/web3dart.dart';

void main() {
	var baz = new ContractFunction("baz",
			[
				new FunctionParameter("number", new UintType(M: 32)),
				new FunctionParameter("flag", new BoolType()),
			]
	);
	var bar = new ContractFunction("bar",
			[
				new FunctionParameter(
						"xy", new StaticLengthArrayType(new StaticLengthBytes(3), 2)
				),
			]
	);

	group('Function names and parameters', () {
		test("with simple functions", () {
			expect(baz.encodeName(), equals("baz(uint32,bool)"));
			expect(baz.encodeCall([69, true]), equals("0xcdcd77c0"
					+ "0000000000000000000000000000000000000000000000000000000000000045"
					+ "0000000000000000000000000000000000000000000000000000000000000001")
			);
			

			expect(bar.encodeName(), equals("bar(bytes3[2])"));
			expect(bar.encodeCall([[UTF8.encode("abc"), UTF8.encode("def")]]),
					equals("0xfce353f6"
						+ "6162630000000000000000000000000000000000000000000000000000000000"
						+ "6465660000000000000000000000000000000000000000000000000000000000")
			);
		});
	});
}
