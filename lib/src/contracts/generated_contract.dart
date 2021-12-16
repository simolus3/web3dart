import 'package:meta/meta.dart';

import '../../crypto.dart';
import '../../web3dart.dart';

/// Base classes for generated contracts.
///
/// web3dart can generate contract classes from abi specifications. For more
/// information, see its readme!
abstract class GeneratedContract {
  final DeployedContract self;
  final Web3Client client;
  final int? chainId;

  GeneratedContract(this.self, this.client, this.chainId);

  /// Returns whether the [function] has the [expected] selector.
  ///
  /// This is used in an assert in the generated code.
  @protected
  bool checkSignature(ContractFunction function, String expected) {
    return bytesToHex(function.selector) == expected;
  }

  @protected
  Future<List<dynamic>> read(
      ContractFunction function, List<dynamic> params, BlockNum? atBlock) {
    return client.call(
        contract: self, function: function, params: params, atBlock: atBlock);
  }

  @protected
  Future<String> write(Credentials credentials, Transaction? base,
      ContractFunction function, List<dynamic> parameters) {
    final transaction = base?.copyWith(
          data: function.encodeCall(parameters),
          to: self.address,
        ) ??
        Transaction.callContract(
            contract: self, function: function, parameters: parameters);

    return client.sendTransaction(credentials, transaction,
        chainId: chainId, fetchChainIdFromNetworkId: chainId == null);
  }
}
