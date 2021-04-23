import 'package:test/test.dart';
import 'package:web3dart/contracts.dart';

final abiTypes = <String, AbiType>{
  'uint256': const UintType(),
  'int32': const IntType(length: 32),
  'bool': const BoolType(),
  'bytes16[]': const DynamicLengthArray(type: FixedBytes(16)),
  'bytes[16]': const FixedLengthArray(type: DynamicBytes(), length: 16),
  '(bool,uint8,string)':
      const TupleType([BoolType(), UintType(length: 8), StringType()]),
  '(uint256,(bool,bytes8)[6])[]': const DynamicLengthArray(
    type: TupleType([
      UintType(),
      FixedLengthArray(
        type: TupleType([
          BoolType(),
          FixedBytes(8),
        ]),
        length: 6,
      ),
    ]),
  ),
};

final invalidTypes = [
  'uint512',
  'bööl',
  '(uint,string',
  'uint19',
  'int32[three]'
];

void main() {
  test('calculates padding length', () {
    expect(calculatePadLength(0), 32);
    expect(calculatePadLength(0, allowEmpty: true), 0);
    expect(calculatePadLength(32), 0);
    expect(calculatePadLength(5), 27);
    expect(calculatePadLength(5, allowEmpty: true), 27);
    expect(calculatePadLength(40), 24);
  });

  test('parses ABI types', () {
    abiTypes.forEach((key, type) {
      expect(parseAbiType(key), type, reason: 'parsAbiType($key)');
      expect(type.name, key);
    });
  });

  test('rejects invalid types', () {
    for (final invalid in invalidTypes) {
      expect(
        () => parseAbiType(invalid),
        throwsA(anything),
        reason: '$invalid is not a valid type',
      );
    }
  });
}
