import 'dart:convert';

import 'package:test/test.dart';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/src/utils/typed_data.dart';

void main() {
  const baz = ContractFunction('baz', [
    FunctionParameter('number', UintType(length: 32)),
    FunctionParameter('flag', BoolType()),
  ]);
  const bar = ContractFunction('bar', [
    FunctionParameter(
      'xy',
      FixedLengthArray(type: FixedBytes(3), length: 2),
    ),
  ]);

  const sam = ContractFunction('sam', [
    FunctionParameter('b1', DynamicBytes()),
    FunctionParameter('b2', BoolType()),
    FunctionParameter('b3', DynamicLengthArray(type: UintType()))
  ], outputs: [
    FunctionParameter('b1', DynamicBytes()),
    FunctionParameter('b2', BoolType()),
    FunctionParameter('b3', DynamicLengthArray(type: UintType()))
  ]);

  test('parses contract abi', () {
    // Taken from: https://solidity.readthedocs.io/en/develop/abi-spec.html#handling-tuple-types

    final abi = ContractAbi.fromJson('''
[
  {
    "name": "f",
    "type": "function",
    "inputs": [
      {
        "name": "s",
        "type": "tuple",
        "components": [
          {
            "name": "a",
            "type": "uint256"
          },
          {
            "name": "b",
            "type": "uint256[]"
          },
          {
            "name": "c",
            "type": "tuple[]",
            "components": [
              {
                "name": "x",
                "type": "uint256"
              },
              {
                "name": "y",
                "type": "uint256"
              }
            ]
          }
        ]
      },
      {
        "name": "t",
        "type": "tuple",
        "components": [
          {
            "name": "x",
            "type": "uint256"
          },
          {
            "name": "y",
            "type": "uint256"
          }
        ]
      },
      {
        "name": "a",
        "type": "uint256"
      }
    ],
    "outputs": []
  }
]
     ''', 'name');

    // Declaration of the function in solidity:
    // struct S { uint a; uint[] b; T[] c; }
    // struct T { uint x; uint y; }
    // function f(S memory s, T memory t, uint a) public;
    final function = abi.functions.single;

    expect(function.name, 'f');
    expect(function.outputs, isEmpty);
    expect(function.isPayable, false);
    expect(function.isConstant, false);
    expect(function.isConstructor, false);
    expect(function.isDefault, false);

    final s = function.parameters[0];
    final t = function.parameters[1];
    final a = function.parameters[2];

    expect(s.name, 's');
    expect(t.name, 't');
    expect(a.name, 'a');

    // todo write expects for s and t. These are so annoying to write, maybe
    // just override hashCode and equals?

    expect(() {
      final type = a.type;
      return type is UintType && type.length == 256;
    }(), true);
  });

  test('functions en- and decode data', () {
    expect(baz.encodeName(), equals('baz(uint32,bool)'));
    expect(
        bytesToHex(baz.encodeCall([BigInt.from(69), true]), include0x: true),
        '0xcdcd77c0'
        '0000000000000000000000000000000000000000000000000000000000000045'
        '0000000000000000000000000000000000000000000000000000000000000001');

    expect(bar.encodeName(), equals('bar(bytes3[2])'));
    expect(
        bytesToHex(
            bar.encodeCall([
              [
                uint8ListFromList(utf8.encode('abc')),
                uint8ListFromList(utf8.encode('def')),
              ]
            ]),
            include0x: true),
        '0xfce353f6'
        '6162630000000000000000000000000000000000000000000000000000000000'
        '6465660000000000000000000000000000000000000000000000000000000000');

    expect(
        bytesToHex(
            sam.encodeCall([
              uint8ListFromList(utf8.encode('dave')),
              true,
              [BigInt.from(1), BigInt.from(2), BigInt.from(3)]
            ]),
            include0x: true),
        '0xa5643bf20000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000464617665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003');

    expect(
        sam
            .decodeReturnValues(
                '0x0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000464617665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003')
            .first,
        equals(utf8.encode('dave')));
  });
}
