part of 'package:web3dart/credentials.dart';

class SignaturesForPrivateKey extends SignatureComputer<EthPrivateKey> {
  static const _messagePrefix = '\u0019Ethereum Signed Message:\n';

  const SignaturesForPrivateKey();

  /// The instance created will use [runner] to run expensive cryptographic
  /// algorithms.
  ///
  /// By providing an `IsolateRunner`, this can reduce the work on the ui thread
  /// for Flutter apps.
  factory SignaturesForPrivateKey.withRunner(Runner runner) =
      _IsolateSignatureComputer;

  @override
  Future<EthereumAddress> extractAddress(EthPrivateKey credential) {
    return Future.value(credential.address);
  }

  @override
  Future<Uint8List> signPersonalMessage(
      Uint8List payload, EthPrivateKey credentials,
      {int chainId}) {
    final prefixBytes =
        ascii.encode(_messagePrefix + payload.length.toString());
    final concat = uint8ListFromList(prefixBytes + payload);
    return signRaw(concat, credentials, chainId: chainId);
  }

  @override
  Future<Uint8List> signRaw(Uint8List payload, EthPrivateKey credentials,
      {int chainId}) {
    final signature = _signToSignature(payload, credentials, chainId: chainId);
    return signature.then((value) => value.encode());
  }

  Future<MsgSignature> _signToSignature(
      Uint8List payload, EthPrivateKey credentials,
      {int chainId}) {
    final signature = sign(keccak256(payload), credentials.privateKey);

    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
    // be aware that signature.v already is recovery + 27
    final chainIdV =
        chainId != null ? (signature.v - 27 + (chainId * 2 + 35)) : signature.v;

    return Future.value(MsgSignature(signature.r, signature.s, chainIdV));
  }

  @override
  Future<Uint8List> signTransaction(
      Transaction transaction, EthPrivateKey credentials,
      {int chainId}) async {
    final innerSignature = chainId == null
        ? null
        : MsgSignature(BigInt.zero, BigInt.zero, chainId);

    final encoded = uint8ListFromList(
        rlp.encode(rlp.destructureTransaction(transaction, innerSignature)));
    final signature =
        await _signToSignature(encoded, credentials, chainId: chainId);

    return uint8ListFromList(
        rlp.encode(rlp.destructureTransaction(transaction, signature)));
  }
}

/// Credentials that can sign payloads with an Ethereum private key.
class EthPrivateKey extends Credentials {
  static const _computer = SignaturesForPrivateKey();

  final Uint8List privateKey;
  EthereumAddress _cachedAddress;

  EthPrivateKey(this.privateKey);

  EthPrivateKey.fromHex(String hex) : privateKey = hexToBytes(hex);

  /// Creates a new, random private key from the [random] number generator.
  ///
  /// For security reasons, it is very important that the random generator used
  /// is cryptographically secure. The private key could be reconstructed by
  /// someone else otherwise. Just using [Random()] is a very bad idea! At least
  /// use [Random.secure()].
  factory EthPrivateKey.createRandom(Random random) {
    final key = generateNewPrivateKey(random);
    return EthPrivateKey(intToBytes(key));
  }

  /// The Ethereum address of this private key.
  EthereumAddress get address {
    return _cachedAddress ??= EthereumAddress(
        publicKeyToAddress(privateKeyBytesToPublic(privateKey)));
  }

  @Deprecated('Use address instead')
  Future<EthereumAddress> extractAddress() {
    return Future.value(address);
  }

  @Deprecated('Use SignaturesForPrivateKey.sign instead')
  Future<MsgSignature> signToSignature(Uint8List payload, {int chainId}) {
    return _computer._signToSignature(payload, this, chainId: chainId);
  }

  @Deprecated('Use SignaturesForPrivateKey.signPersonalMessage instead')
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int chainId}) {
    return _computer.signPersonalMessage(payload, this, chainId: chainId);
  }

  @Deprecated('Use SignaturesForPrivateKey.signRaw instead')
  Future<Uint8List> sign(Uint8List payload, {int chainId}) {
    return _computer.signRaw(payload, this, chainId: chainId);
  }
}
