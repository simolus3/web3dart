part of 'package:web3dart/web3dart.dart';

/// Wrapper around some potentially expensive operations so that they can
/// optionally be executed in a background isolate. This is mainly needed for
/// flutter apps where these would otherwise block the UI thread.
class _ExpensiveOperations {
  final Runner runner;

  _ExpensiveOperations(this.runner);

  Future stop() {
    return runner.close();
  }

  Future<EthPrivateKey> privateKeyFromHex(String privateKey) {
    return runner.run(_internalCreatePrivateKey, privateKey);
  }

  Future<Uint8List> signTransaction(_SigningInput t) {
    if (!t.credentials.isolateSafe) {
      // sign on this isolate
      return internalSign(t);
    } else {
      return runner.run(internalSign, t);
    }
  }
}

Future<EthPrivateKey> _internalCreatePrivateKey(String hex) async {
  final key = EthPrivateKey.fromHex(hex);
  // extracting the address is the expensive operation here. It will be
  // cached, so we only need to do this once
  await key.extractAddress();
  return key;
}

Future<Uint8List> internalSign(_SigningInput t) {
  return _signTransaction(t.transaction, t.credentials, t.chainId);
}
