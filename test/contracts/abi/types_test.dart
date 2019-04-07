import 'package:test_api/test_api.dart';
import 'package:web3dart/contracts.dart';

void main() {
  test('calculates padding length', () {
    expect(calculatePadLength(0), 32);
    expect(calculatePadLength(32), 0);
    expect(calculatePadLength(5), 27);
    expect(calculatePadLength(40), 24);
  });

  test('parses ABI types', () {
    expect(parseAbiType('uint'), const UintType());
  });
}