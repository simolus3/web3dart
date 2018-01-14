import 'dart:math';
import 'dart:typed_data';

import 'package:bignum/bignum.dart';
import 'package:pointycastle/api.dart';

/// Utility to use dart:math's Random class to generate numbers used by
/// pointycastle.
class DartRandom implements SecureRandom {

	Random dartRandom;

	DartRandom(this.dartRandom);

  @override
  String get algorithmName => "DartRandom";

  @override
  BigInteger nextBigInteger(int bitLength) {
    var fullBytes = bitLength ~/ 8;
    var remainingBits = bitLength % 8;
    
    var main = new BigInteger.fromBytes(1, nextBytes(fullBytes));
    var additional = dartRandom.nextInt(pow(2, remainingBits));
    return main.add(new BigInteger(additional).shiftRight(fullBytes * 8));
  }

  @override
  Uint8List nextBytes(int count) {
    var list = new Uint8List(count);

    for (var i = 0; i < list.length; i++) {
    	list[i] = nextUint8();
		}

		return list;
  }

  @override
  int nextUint16()  => dartRandom.nextInt(pow(2, 32));

  @override
  int nextUint32() => dartRandom.nextInt(pow(2, 32));

  @override
  int nextUint8() => dartRandom.nextInt(pow(2, 8));

  @override
  void seed(CipherParameters params) {
    // ignore, dartRandom will already be seeded if wanted
  }
}