part of 'package:web3dart/credentials.dart';

class _IsolateSignatureComputer extends SignaturesForPrivateKey {
  final Runner runner;

  _IsolateSignatureComputer(this.runner);

  @override
  Future<MsgSignature> _signToSignature(
      Uint8List payload, EthPrivateKey credentials,
      {int chainId}) {
    return runner.run(
        _internalSign, _SigningData(payload, credentials, chainId));
  }
}

class _SigningData {
  final Uint8List payload;
  final EthPrivateKey privateKey;
  final int chainId;

  _SigningData(this.payload, this.privateKey, this.chainId);
}

Future<MsgSignature> _internalSign(_SigningData t) {
  return const SignaturesForPrivateKey()
      ._signToSignature(t.payload, t.privateKey, chainId: t.chainId);
}
