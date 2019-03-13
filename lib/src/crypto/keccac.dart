part of 'package:web3dart/crypto.dart';

const int _shaBytes = 256 ~/ 8;
// keccak is implemented as sha3 digest in pointycastle, see
// https://github.com/PointyCastle/pointycastle/issues/128
final SHA3Digest sha3digest = SHA3Digest(_shaBytes * 8);

Uint8List keccak256(Uint8List input) {
  sha3digest.reset();
  return sha3digest.process(input);
}