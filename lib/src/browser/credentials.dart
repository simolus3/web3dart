import 'dart:typed_data';

import '../../credentials.dart';
import '../../crypto.dart';

import 'dart_wrappers.dart';
import 'javascript.dart';

class MetaMaskCredentials extends CredentialsWithKnownAddress {
  @override
  final EthereumAddress address;
  final Ethereum ethereum;

  MetaMaskCredentials(String hexAddress, this.ethereum)
      : address = EthereumAddress.fromHex(hexAddress);

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int? chainId}) {
    throw UnsupportedError('Signing raw payloads is not supported on MetaMask');
  }

  @override
  Future<Uint8List> signPersonalMessage(Uint8List payload, {int? chainId}) {
    return ethereum.rawRequest('eth_sign', params: [
      address.hex,
      bytesToHex(payload, include0x: true, padToEvenLength: true),
    ]).then((res) => hexToBytes(res as String));
  }
}
