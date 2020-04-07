part of 'package:web3dart/metamask.dart';

class MetaMaskSignatures extends SignatureComputer<MetaMaskAccount> {
  const MetaMaskSignatures();

  @override
  Future<EthereumAddress> extractAddress(MetaMaskAccount credential) {
    return Future.value(credential.address);
  }

  @override
  Future<Uint8List> signRaw(Uint8List payload, MetaMaskAccount credentials,
      {int chainId}) {
    throw UnsupportedError('signRaw is not supported on MetaMask');
  }

  @override
  Future<Uint8List> signPersonalMessage(
      Uint8List payload, MetaMaskAccount credentials,
      {int chainId}) {
    return credentials._handle._send('eth_sign', [
      credentials._rawHexAddress,
      _bytesToData(payload)
    ]).then(_dynamicHexToBytes);
  }

  @override
  Future<Uint8List> signTransaction(
      Transaction transaction, MetaMaskAccount credentials,
      {int chainId}) {
    return credentials._handle
        ._send(
          'eth_signTransaction',
          [
            transaction.from.hex,
            transaction.to.hex,
            '0x${transaction.maxGas.toRadixString(16)}',
            _intToQuantity(transaction.gasPrice.getInWei),
            _intToQuantity(transaction.value.getInWei),
            _bytesToData(transaction.data),
            '0x${transaction.nonce.toRadixString(16)}',
          ],
          credentials._rawHexAddress,
        )
        .then(_dynamicHexToBytes);
  }

  String _intToQuantity(BigInt int) {
    return '0x${int.toRadixString(16)}';
  }

  String _bytesToData(Uint8List list) {
    return bytesToHex(list, include0x: true, padToEvenLength: true);
  }

  Uint8List _dynamicHexToBytes(dynamic value) {
    return hexToBytes(value as String);
  }
}
