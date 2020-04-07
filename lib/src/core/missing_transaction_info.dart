part of 'package:web3dart/web3dart.dart';

class _TransactionWithChainId {
  final Transaction transaction;
  final int chainId;

  _TransactionWithChainId({this.transaction, this.chainId});
}

Future<_TransactionWithChainId> _fillMissingData({
  @required Credentials credentials,
  @required SignatureComputer computer,
  @required Transaction transaction,
  int chainId,
  bool loadChainIdFromNetwork = false,
  Web3Client client,
}) async {
  assert(credentials != null);
  assert(transaction != null);
  assert(loadChainIdFromNetwork != null);
  assert(!loadChainIdFromNetwork || chainId != null,
      "You can't specify loadChainIdFromNetwork and specify a custom chain id!");

  // apply default values to null fields
  var modifiedTransaction = transaction.copyWith(
    value: transaction.value ?? EtherAmount.zero(),
    maxGas: transaction.maxGas ?? 90000,
    from: transaction.from ?? await computer.extractAddress(credentials),
    data: transaction.data ?? Uint8List(0),
  );

  int resolvedChainId;
  if (!loadChainIdFromNetwork) {
    resolvedChainId = chainId;
  } else {
    if (client == null) {
      throw ArgumentError(
          "Can't load chain id from network when no client is set");
    }

    resolvedChainId = await client.getNetworkId();
  }

  if (modifiedTransaction.maxGas == null) {
    // use default from https://github.com/ethereum/wiki/wiki/JSON-RPC#parameters-22
    modifiedTransaction = modifiedTransaction.copyWith(
      maxGas: 90000,
    );
  }

  if (modifiedTransaction.gasPrice == null) {
    if (client == null) {
      throw ArgumentError("Can't find suitable gas price from client because "
          'no client is set. Please specify a gas price on the transaction.');
    }

    modifiedTransaction = modifiedTransaction.copyWith(
      gasPrice: await client.getGasPrice(),
    );
  }

  if (modifiedTransaction.nonce == null) {
    if (client == null) {
      throw ArgumentError("Can't find the correct nonce because no client is "
          'is set. Please specify a nonce in the transaction or specify a '
          'client.');
    }

    modifiedTransaction = modifiedTransaction.copyWith(
      nonce: await client.getTransactionCount(modifiedTransaction.from),
    );
  }

  return _TransactionWithChainId(
    transaction: modifiedTransaction,
    chainId: resolvedChainId,
  );
}
