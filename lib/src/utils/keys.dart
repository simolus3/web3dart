import 'dart:math';
import 'dart:typed_data';
import 'numbers.dart' as numbers;

import 'package:pointycastle/api.dart';
import "package:pointycastle/digests/sha256.dart";
import "package:pointycastle/digests/sha3.dart";
import "package:pointycastle/ecc/api.dart";
import "package:pointycastle/ecc/curves/secp256k1.dart";
import 'package:pointycastle/key_generators/api.dart';
import "package:pointycastle/key_generators/ec_key_generator.dart";
import "package:pointycastle/macs/hmac.dart";
import "package:pointycastle/signers/ecdsa_signer.dart";
import 'package:web3dart/src/utils/dartrandom.dart';

final ECDomainParameters _params = new ECCurve_secp256k1();
final BigInt _HALF_CURVE_ORDER = _params.n ~/ BigInt.two;

const int _SHA_BYTES = 256 ~/ 8;
final SHA3Digest sha3digest = new SHA3Digest(_SHA_BYTES * 8);

/// Signatures used to sign Ethereum transactions and messages.
class MsgSignature {
	final BigInt r;
	final BigInt s;
	final int v;

	MsgSignature(this.r, this.s, this.v);
}

Uint8List sha3(Uint8List input) {
	sha3digest.reset();
	return sha3digest.process(input);
}

/// Generates a new private key using the random instance provided. Please make
/// sure you're using a cryptographically secure generator.
BigInt generateNewPrivateKey(Random random) {
	ECKeyGenerator generator = new ECKeyGenerator();

	var keyParams = new ECKeyGeneratorParameters(_params);

	generator.init(new ParametersWithRandom(keyParams, new DartRandom(random)));

	AsymmetricKeyPair<ECPublicKey, ECPrivateKey> key = generator.generateKeyPair();
	return key.privateKey.d;
}

/**
 * Generates a public key for the given private key using the ecdsa curve which
 * Ethereum uses.
 */
Uint8List privateKeyToPublic(Uint8List privateKey) {
	var privateKeyNum = numbers.bytesToInt(privateKey);
	ECPoint p = _params.G * privateKeyNum;

	//skip the type flag, https://github.com/ethereumjs/ethereumjs-util/blob/master/index.js#L319
	return p.getEncoded(false).sublist(1);
}

/**
 * Constructs the Ethereum address associated with the given public key by
 * taking the lower 160 bits of the key's sha3 hash.
 */
Uint8List publicKeyToAddress(Uint8List publicKey) {
	assert(publicKey.length == 64);

	var hashed = sha3digest.process(publicKey);
	return hashed.sublist(_SHA_BYTES - 20);
}

/// Signs the hashed data in [messageHash] using the given private key.
MsgSignature sign(Uint8List messageHash, Uint8List privateKey) {
	var digest = new SHA256Digest();
	var signer = new ECDSASigner(null, new HMac(digest, 64));
	var key = new ECPrivateKey(numbers.bytesToInt(privateKey), _params);

	signer.init(true, new PrivateKeyParameter(key));
	ECSignature sig = signer.generateSignature(messageHash);

	/*
	This is necessary because if a message can be signed by (r, s), it can also
	be signed by (r, -s (mod N)) which N being the order of the elliptic function
	used. In order to ensure transactions can't be tampered with (even though it
	would be harmless), Ethereum only accepts the signature with the lower value
	of s to make the signature for the message unique.
	More details at
	https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/ECDSASignature.java#L27
	 */
	if (sig.s.compareTo(_HALF_CURVE_ORDER) > 0) {
		var canonicalisedS = _params.n - sig.s;
		sig = new ECSignature(sig.r, canonicalisedS);
	}

	var publicKey = numbers.bytesToInt(privateKeyToPublic(privateKey));

	//Implementation for calculating v naively taken from there, I don't understand
	//any of this.
	//https://github.com/web3j/web3j/blob/master/crypto/src/main/java/org/web3j/crypto/Sign.java
	int recId = -1;
	for (int i = 0; i < 4; i++) {
		var k = _recoverFromSignature(i, sig, messageHash, _params);
		if (k == publicKey) {
			recId = i;
			break;
		}
	}

	if (recId == -1) {
		throw new Exception("Could not construct a recoverable key. This should never happen");
	}

	return new MsgSignature(sig.r, sig.s, recId + 27);
}

BigInt _recoverFromSignature(int recId, ECSignature sig, Uint8List msg, ECDomainParameters params) {
	BigInt n = params.n;
	BigInt i = new BigInt.from(recId ~/ 2);
	BigInt x = sig.r + (i * n);

	//Parameter q of curve
	BigInt prime = BigInt.parse("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", radix: 16);
	if (x.compareTo(prime) >= 0)
		return null;

	var R = _decompressKey(x, (recId & 1) == 1, params.curve);
	if (!(R * n).isInfinity)
		return null;

	var e = numbers.bytesToInt(msg);

	var eInv = (BigInt.zero - e) % n;
	var rInv = sig.r.modInverse(n);
	var srInv = (rInv * sig.s) % n;
	var eInvrInv = (rInv * eInv) % n;

	var q = (params.G * eInvrInv) + (R * srInv);

	var bytes = q.getEncoded(false);
	return numbers.bytesToInt(bytes.sublist(1));
}

ECPoint _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
	List<int> x9IntegerToBytes(BigInt s, int qLength) {
		//https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/asn1/x9/X9IntegerConverter.java#L45
		var bytes = numbers.intToBytes(s);

		if (qLength < bytes.length) {
			return bytes.sublist(0, bytes.length - qLength);
		} else if (qLength > bytes.length) {
			var tmp = new List<int>.filled(qLength, 0);

			var offset = qLength - bytes.length;
			for (int i = 0; i < bytes.length; i++) {
				tmp[i + offset] = bytes[i];
			}

			return tmp;
		}

		return bytes;
	}

	var compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
	compEnc[0] = yBit ? 0x03 : 0x02;
	return c.decodePoint(compEnc);
}