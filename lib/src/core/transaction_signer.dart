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

  final sender = transaction.from ?? await credentials.extractAddress();
  var gasPrice = transaction.gasPrice;
  var nonce = transaction.nonce;
  if (gasPrice == null || nonce == null) {
    if (client == null) {
      throw ArgumentError("Can't find suitable gas price and nonce from client "
          'because no client is set. Please specify a gas price on the '
          'transaction.');
    }
    gasPrice ??= await client.getGasPrice();
    nonce ??= await client.getTransactionCount(sender,
        atBlock: const BlockNum.pending());
  }

  final maxGas = transaction.maxGas ??
      await client
          .estimateGas(
            sender: sender,
            to: transaction.to,
            data: transaction.data,
            value: transaction.value,
            gasPrice: gasPrice,
          )
          .then((bigInt) => bigInt.toInt());

  // apply default values to null fields
  final modifiedTransaction = transaction.copyWith(
    value: transaction.value ?? EtherAmount.zero(),
    maxGas: maxGas,
    from: sender,
    data: transaction.data ?? Uint8List(0),
    gasPrice: gasPrice,
    nonce: nonce,
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
    list.add('');
  }

  list..add(transaction.value.getInWei)..add(transaction.data);

  if (signature != null) {
    list..add(signature.v)..add(signature.r)..add(signature.s);
  }

  return list;
}
