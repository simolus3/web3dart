import 'dart:math';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:web3dart/src/crypto/random_bridge.dart';

class MockRandom extends Mock implements Random {}

void main() {
  final random = MockRandom();
  // generating numbers in [0;1<<32] is supported by the RNG implemented in
  // dart.
  when(random.nextInt(any)).thenAnswer((i) {
    final max = i.positionalArguments.first as int;
    if (max > (1 << 32)) {
      fail('RandomBridge called Random.nextInt with an upper bound that is '
          'to high.');
    } else {
      return max ~/ 2;
    }
  });

  setUp(() {
    clearInteractions(random);
  });

  test('delegates simple operations', () {
    expect(RandomBridge(random).nextUint8(), 1 << 7);
    expect(RandomBridge(random).nextUint16(), 1 << 15);
    expect(RandomBridge(random).nextUint32(), 1 << 31);
  });

  test('generates bytes', () {
    // chosen by fair dice roll. guaranteed to be random
    when(random.nextInt(1 << 8)).thenReturn(4);

    expect(RandomBridge(random).nextBytes(5), [4, 4, 4, 4, 4]);
  });

  test('generates big integers', () {
    when(random.nextInt(1 << 8)).thenReturn(84);
    when(random.nextInt(1 << 5)).thenReturn(12);

    expect(RandomBridge(random).nextBigInteger(13).toInt(), (12 << 8) + 84);
  });
}
