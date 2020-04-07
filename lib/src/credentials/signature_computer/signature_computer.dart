part of 'package:web3dart/credentials.dart';

abstract class SignatureComputer<C extends Credentials> {
  const SignatureComputer();

  /// Loads the ethereum address specified by the [Credentials].
  Future<EthereumAddress> extractAddress(C credential);

  /// Signs the [payload] with a private key and returns the obtained
  /// signature.
  ///
  /// This method might not be available on platforms. In particular, it's not
  /// available on MetaMask.
  Future<Uint8List> signRaw(Uint8List payload, C credentials, {int chainId});

  /// Signs an Ethereum specific signature. This method is equivalent to
  /// [signRaw], but with a special prefix so that this method can't be used to
  /// sign, for instance, transactions.
  Future<Uint8List> signPersonalMessage(Uint8List payload, C credentials,
      {int chainId});

  /// Signs the [transaction] with the provided [Credentials].
  ///
  /// Optionally, a custom [chainId] can be specified.
  Future<Uint8List> signTransaction(Transaction transaction, C credentials,
      {int chainId});

  bool supportsCredentials(Credentials c) => c is C;
}
