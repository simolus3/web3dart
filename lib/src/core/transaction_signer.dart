part of 'package:web3dart/web3dart.dart';

class _SigningInput {
  final Transaction transaction;
  final Credentials credentials;
  final int chainId;

  _SigningInput({this.transaction, this.credentials, this.chainId});
}

Future<_SigningInput> _fillMissingData({
  @required Credentials credentials,
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
    from: transaction.from ?? await credentials.extractAddress(),
    data: transaction.data ?? Uint8List(0),
  );

  int resolvedChainId;
  if (!loadChainIdFromNetwork) {
    resolvedChainId = chainId;
  } else {
    if (client == null)
      throw ArgumentError(
          "Can't load chain id from network when no client is set");

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

  return _SigningInput(
    transaction: modifiedTransaction,
    credentials: credentials,
    chainId: resolvedChainId,
  );
}

Future<Uint8List> _signTransaction(
    Transaction transaction, Credentials c, int chainId) async {
  final innerSignature =
      chainId == null ? null : MsgSignature(BigInt.zero, BigInt.zero, chainId);

  final encoded =
      uint8ListFromList(rlp.encode(_encodeToRlp(transaction, innerSignature)));
  final signature = await c.signToSignature(encoded, chainId: chainId);

  return uint8ListFromList(rlp.encode(_encodeToRlp(transaction, signature)));
}

List<dynamic> _encodeToRlp(Transaction transaction, MsgSignature signature) {
  final list = [
    transaction.nonce,
    transaction.gasPrice.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to.addressBytes);
  } else {
    list.add([]);
  }

  list..add(transaction.value.getInWei)..add(transaction.data);

  if (signature != null) {
    list..add(signature.v)..add(signature.r)..add(signature.s);
  }

  return list;
}
