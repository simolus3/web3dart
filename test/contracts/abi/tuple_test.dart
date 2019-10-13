import 'package:test/test.dart';
import 'package:web3dart/contracts.dart';

import 'utils.dart';

// https://solidity.readthedocs.io/en/develop/abi-spec.html#examples

const dynamicTuple = TupleType([
  StringType(),
  BoolType(),
  DynamicLengthArray(type: UintType()),
]);

final dynamicData = [
  'dave',
  true,
  [BigInt.from(1), BigInt.from(2), BigInt.from(3)],
];

final dynamicEncoded =
    '0000000000000000000000000000000000000000000000000000000000000060'
    '0000000000000000000000000000000000000000000000000000000000000001'
    '00000000000000000000000000000000000000000000000000000000000000a0'
    '0000000000000000000000000000000000000000000000000000000000000004'
    '6461766500000000000000000000000000000000000000000000000000000000'
    '0000000000000000000000000000000000000000000000000000000000000003'
    '0000000000000000000000000000000000000000000000000000000000000001'
    '0000000000000000000000000000000000000000000000000000000000000002'
    '0000000000000000000000000000000000000000000000000000000000000003';

const staticTuple = TupleType([
  UintType(length: 32),
  BoolType(),
]);

final staticData = [BigInt.from(0x45), true];

final staticEncoded =
    '0000000000000000000000000000000000000000000000000000000000000045'
    '0000000000000000000000000000000000000000000000000000000000000001';

void main() {
  test('reports name', () {
    expect(dynamicTuple.name, '(string,bool,uint256[])');
    expect(staticTuple.name, '(uint32,bool)');
  });

  test('reports encoding length', () {
    expect(dynamicTuple.encodingLength.isDynamic, true);
    expect(staticTuple.encodingLength.length, 2 * sizeUnitBytes);
  });

  test('encodes values', () {
    expectEncodes(staticTuple, staticData, staticEncoded);
    expectEncodes(dynamicTuple, dynamicData, dynamicEncoded);
  });

  test('decodes values', () {
    expect(
        staticTuple.decode(bufferFromHex(staticEncoded), 0).data, staticData);
    expect(dynamicTuple.decode(bufferFromHex(dynamicEncoded), 0).data,
        dynamicData);
  });
}
