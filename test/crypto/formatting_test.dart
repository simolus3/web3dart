import 'package:test_api/test_api.dart';
import 'package:web3dart/crypto.dart';

void main() {
  test('strip 0x prefix', () {
    expect(strip0x('0x12F312319235'), '12F312319235');
    expect(strip0x('123123'), '123123');
  });
}
