part of 'package:web3dart/credentials.dart';

/// The sign method from sec256k1, so that it can be used inside [Credentials].
const _globalSign = sign;

/// Anything that can sign payloads with a private key.
abstract class Credentials {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  /// Whether these [Credentials] are safe to be copied to another isolate and
  /// can operate there.
  /// If this getter returns true, the client might chose to perform the
  /// expensive signing operations on another isolate.
  bool get isolateSafe => false;

  /// Loads the ethereum address specified by these credentials.
  Future<EthereumAddress> extractAddress();

  /// Signs the [payload] with a private key. The output will be like the
  /// bytes representation of the [eth_sign RPC method](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign),
  /// but without the "Ethereum signed message" prefix.
  /// The [payload] parameter contains the raw data, not a hash.
  Future<Uint8List> sign(Uint8List payload, {int chainId}) async {
    final signature = await signToSignature(payload, chainId: chainId);

    final r = _padTo32(intToBytes(signature.r));
    final s = _padTo32(intToBytes(signature.s));
    final v = intToBytes(BigInt.from(signature.v));

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
    return uint8ListFromList(r + s + v);
  }

  /// Signs the [payload] with a private key and returns the obtained
  /// signature.
  Future<MsgSignature> signToSignature(Uint8List payload, {int chainId});

  /// Signs an Ethereum specific signature. This method is equivalent to
  /// [sign], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int chainId}) {
    final prefix = _messagePrefix + payload.length.toString();
    final prefixBytes = ascii.encode(prefix);

    // will be a Uint8List, see the documentation of Uint8List.+
    final concat = uint8ListFromList(prefixBytes + payload);

    return sign(concat, chainId: chainId);
  }

  Uint8List _padTo32(Uint8List data) {
    assert(data.length <= 32);
    if (data.length == 32) return data;

    // todo there must be a faster way to do this?
    return Uint8List(32)..setRange(32 - data.length, 32, data);
  }
}

/// Credentials that can sign payloads with an Ethereum private key.
class EthPrivateKey extends Credentials {
  final Uint8List privateKey;
  EthereumAddress _cachedAddress;

  EthPrivateKey(this.privateKey);

  EthPrivateKey.fromHex(String hex) : privateKey = hexToBytes(hex);

  @override
  final bool isolateSafe = true;

  @override
  Future<EthereumAddress> extractAddress() async {
    return _cachedAddress ??= EthereumAddress(
        publicKeyToAddress(privateKeyBytesToPublic(privateKey)));
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int chainId}) async {
    final signature = _globalSign(keccak256(payload), privateKey);

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    // be aware that signature.v already is recovery + 27
    final chainIdV =
        chainId != null ? (signature.v - 27 + (chainId * 2 + 35)) : signature.v;

    return MsgSignature(signature.r, signature.s, chainIdV);
  }
}
