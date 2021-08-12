import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

import '../utils/typed_data.dart';
import 'formatting.dart';
import 'keccak.dart';
import 'random_bridge.dart';

@internal
final ECDomainParameters params = ECCurve_secp256k1();
final BigInt _halfCurveOrder = params.n >> 1;

/// Generates a public key for the given private key using the ecdsa curve which
/// Ethereum uses.
Uint8List privateKeyBytesToPublic(Uint8List privateKey) {
  return privateKeyToPublic(bytesToUnsignedInt(privateKey));
}

/// Generates a public key for the given private key using the ecdsa curve which
/// Ethereum uses.
Uint8List privateKeyToPublic(BigInt privateKey) {
  final p = (params.G * privateKey)!;

  //skip the type flag, https://github.com/ethereumjs/ethereumjs-util/blob/master/index.js#L319
  return Uint8List.view(p.getEncoded(false).buffer, 1);
}

/// Generates a new private key using the random instance provided. Please make
/// sure you're using a cryptographically secure generator.
BigInt generateNewPrivateKey(Random random) {
  final generator = ECKeyGenerator();

  final keyParams = ECKeyGeneratorParameters(params);

  generator.init(ParametersWithRandom(keyParams, RandomBridge(random)));

  final key = generator.generateKeyPair();
  final privateKey = key.privateKey as ECPrivateKey;
  return privateKey.d!;
}

/// Constructs the Ethereum address associated with the given public key by
/// taking the lower 160 bits of the key's sha3 hash.
Uint8List publicKeyToAddress(Uint8List publicKey) {
  assert(publicKey.length == 64);
  final hashed = keccak256(publicKey);
  assert(hashed.length == 32);
  return hashed.sublist(12, 32);
}

/// Signatures used to sign Ethereum transactions and messages.
class MsgSignature {
  final BigInt r;
  final BigInt s;
  final int v;

  MsgSignature(this.r, this.s, this.v);
}

/// Signs the hashed data in [messageHash] using the given private key.
MsgSignature sign(Uint8List messageHash, Uint8List privateKey) {
  final digest = SHA256Digest();
  final signer = ECDSASigner(null, HMac(digest, 64));
  final key = ECPrivateKey(bytesToUnsignedInt(privateKey), params);

  signer.init(true, PrivateKeyParameter(key));
  var sig = signer.generateSignature(messageHash) as ECSignature;

  /*
	This is necessary because if a message can be signed by (r, s), it can also
	be signed by (r, -s (mod N)) which N being the order of the elliptic function
	used. In order to ensure transactions can't be tampered with (even though it
	would be harmless), Ethereum only accepts the signature with the lower value
	of s to make the signature for the message unique.
	More details at
	https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/ECDSASignature.java#L27
	 */
  if (sig.s.compareTo(_halfCurveOrder) > 0) {
    final canonicalisedS = params.n - sig.s;
    sig = ECSignature(sig.r, canonicalisedS);
  }

  final publicKey = bytesToUnsignedInt(privateKeyBytesToPublic(privateKey));

  //Implementation for calculating v naively taken from there, I don't understand
  //any of this.
  //https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/Sign.java
  var recId = -1;
  for (var i = 0; i < 4; i++) {
    final k = _recoverFromSignature(i, sig, messageHash, params);
    if (k == publicKey) {
      recId = i;
      break;
    }
  }

  if (recId == -1) {
    throw Exception(
        'Could not construct a recoverable key. This should never happen');
  }

  return MsgSignature(sig.r, sig.s, recId + 27);
}

/// Given an arbitrary message hash and an Ethereum message signature encoded in bytes, returns
/// the public key that was used to sign it.
/// https://github.com/web3j/web3j/blob/c0b7b9c2769a466215d416696021aa75127c2ff1/crypto/src/main/java/org/web3j/crypto/Sign.java#L241
Uint8List ecRecover(Uint8List messageHash, MsgSignature signatureData) {
  final r = padUint8ListTo32(unsignedIntToBytes(signatureData.r));
  final s = padUint8ListTo32(unsignedIntToBytes(signatureData.s));
  assert(r.length == 32);
  assert(s.length == 32);

  final header = signatureData.v & 0xFF;
  // The header byte: 0x1B = first key with even y, 0x1C = first key with odd y,
  //                  0x1D = second key with even y, 0x1E = second key with odd y
  if (header < 27 || header > 34) {
    throw Exception('Header byte out of range: $header');
  }

  final sig = ECSignature(signatureData.r, signatureData.s);

  final recId = header - 27;
  final pubKey = _recoverFromSignature(recId, sig, messageHash, params);
  if (pubKey == null) {
    throw Exception('Could not recover public key from signature');
  }
  return unsignedIntToBytes(pubKey);
}

/// Given an arbitrary message hash, an Ethereum message signature encoded in bytes and
/// a public key encoded in bytes, confirms whether that public key was used to sign
/// the message or not.
bool isValidSignature(
    Uint8List messageHash, MsgSignature signatureData, Uint8List publicKey) {
  final recoveredPublicKey = ecRecover(messageHash, signatureData);
  return bytesToHex(publicKey) == bytesToHex(recoveredPublicKey);
}

/// Given a byte array computes its compressed version and returns it as a byte array,
/// including the leading 02 or 03
Uint8List compressPublicKey(Uint8List compressedPubKey) {
  return Uint8List.view(
      params.curve.decodePoint(compressedPubKey)!.getEncoded(true).buffer);
}

/// Given a byte array computes its expanded version and returns it as a byte array,
/// including the leading 04
Uint8List decompressPublicKey(Uint8List compressedPubKey) {
  return Uint8List.view(
      params.curve.decodePoint(compressedPubKey)!.getEncoded(false).buffer);
}

BigInt? _recoverFromSignature(
    int recId, ECSignature sig, Uint8List msg, ECDomainParameters params) {
  final n = params.n;
  final i = BigInt.from(recId ~/ 2);
  final x = sig.r + (i * n);

  //Parameter q of curve
  final prime = BigInt.parse(
      'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
      radix: 16);
  if (x.compareTo(prime) >= 0) return null;

  final R = _decompressKey(x, (recId & 1) == 1, params.curve);
  if (!(R * n)!.isInfinity) return null;

  final e = bytesToUnsignedInt(msg);

  final eInv = (BigInt.zero - e) % n;
  final rInv = sig.r.modInverse(n);
  final srInv = (rInv * sig.s) % n;
  final eInvrInv = (rInv * eInv) % n;

  final q = (params.G * eInvrInv)! + (R * srInv);

  final bytes = q!.getEncoded(false);
  return bytesToUnsignedInt(bytes.sublist(1));
}

ECPoint _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
  List<int> x9IntegerToBytes(BigInt s, int qLength) {
    //https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/asn1/x9/X9IntegerConverter.java#L45
    final bytes = intToBytes(s);

    if (qLength < bytes.length) {
      return bytes.sublist(0, bytes.length - qLength);
    } else if (qLength > bytes.length) {
      final tmp = List<int>.filled(qLength, 0);

      final offset = qLength - bytes.length;
      for (var i = 0; i < bytes.length; i++) {
        tmp[i + offset] = bytes[i];
      }

      return tmp;
    }

    return bytes;
  }

  final compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
  compEnc[0] = yBit ? 0x03 : 0x02;
  return c.decodePoint(compEnc)!;
}
