import 'dart:math';
import 'package:test/test.dart';
import 'package:web3dart/src/crypto/random_bridge.dart';

class MockRandom implements Random {
  // using BigInt because 1 << 32 is 0 in js
  static final _twoToThePowerOf32 = BigInt.one << 32;

  final List<int> nextIntResponses = [];

  @override
  bool nextBool() {
    throw UnimplementedError();
  }

  @override
  double nextDouble() {
    throw UnimplementedError();
  }

  @override
  int nextInt(int max) {
    if (BigInt.from(max) > _twoToThePowerOf32) {
      // generating numbers in [0;1<<32] is supported by the RNG implemented in
      // dart.
      fail('RandomBridge called Random.nextInt with an upper bound that is '
          'to high: $max');
    }

    if (nextIntResponses.isNotEmpty) {
      return nextIntResponses.removeAt(0);
    } else {
      return max ~/ 2;
    }
  }
}

void main() {
  final random = MockRandom();

  test('delegates simple operations', () {
    expect(RandomBridge(random).nextUint8(), 1 << 7);
    expect(RandomBridge(random).nextUint16(), 1 << 15);
    expect(RandomBridge(random).nextUint32(), 1 << 31);
  });

  test('generates bytes', () {
    random.nextIntResponses.addAll([4, 4, 4, 4, 4]);

    expect(RandomBridge(random).nextBytes(5), [4, 4, 4, 4, 4]);
  });

  test('generates big integers', () {
    random.nextIntResponses.addAll([84, 12]);
    expect(RandomBridge(random).nextBigInteger(13).toInt(), (12 << 8) + 84);
  });

  test('nextBigInteger is never negative', () {
    final random = RandomBridge(Random());
    for (var i = 1; i < 500; i++) {
      expect(random.nextBigInteger(i), isA());
    }
  });
}
