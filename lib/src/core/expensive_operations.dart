part of 'package:web3dart/web3dart.dart';

Future<EthPrivateKey> privateKeyFromHex(String privateKey) async {
  return _internalCreatePrivateKey(privateKey);
}

Future<EthPrivateKey> _internalCreatePrivateKey(String hex) async {
  final key = EthPrivateKey.fromHex(hex);
  // extracting the address is the expensive operation here. It will be
  // cached, so we only need to do this once
  await key.extractAddress();
  return key;
}

Future<Uint8List> internalSign(_SigningInput t) async {
  return _signTransaction(t.transaction!, t.credentials!, t.chainId);
}
