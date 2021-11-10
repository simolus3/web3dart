part of 'package:web3dart/web3dart.dart';

class _SigningInput {
  _SigningInput(
      {required this.transaction, required this.credentials, this.chainId});

  final Transaction transaction;
  final Credentials credentials;
  final int? chainId;
}

Future<_SigningInput> _fillMissingData({
  required Credentials credentials,
  required Transaction transaction,
  int? chainId,
  bool loadChainIdFromNetwork = false,
  Web3Client? client,
}) async {
  if (loadChainIdFromNetwork && chainId != null) {
    throw ArgumentError(
        "You can't specify loadChainIdFromNetwork and specify a custom chain id!");
  }

  final sender = transaction.from ?? await credentials.extractAddress();
  var gasPrice = transaction.gasPrice;

  if (client == null &&
      (transaction.nonce == null ||
          transaction.maxGas == null ||
          loadChainIdFromNetwork ||
          (!transaction.isEIP1559 && gasPrice == null))) {
    throw ArgumentError('Client is required to perform network actions');
  }

  if (!transaction.isEIP1559 && gasPrice == null) {
    gasPrice = await client!.getGasPrice();
  }

  final nonce = transaction.nonce ??
      await client!
          .getTransactionCount(sender, atBlock: const BlockNum.pending());

  final maxGas = transaction.maxGas ??
      await client!
          .estimateGas(
            sender: sender,
            to: transaction.to,
            data: transaction.data,
            value: transaction.value,
            gasPrice: gasPrice,
            maxPriorityFeePerGas: transaction.maxPriorityFeePerGas,
            maxFeePerGas: transaction.maxFeePerGas,
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
    resolvedChainId = chainId!;
  } else {
    resolvedChainId = await client!.getNetworkId();
  }

  return _SigningInput(
    transaction: modifiedTransaction,
    credentials: credentials,
    chainId: resolvedChainId,
  );
}

Uint8List prependTransactionType(int type, Uint8List transaction) {
  return Uint8List(transaction.length + 1)
    ..[0] = type
    ..setAll(1, transaction);
}

Future<Uint8List> _signTransaction(
    Transaction transaction, Credentials c, int? chainId) async {
  if (transaction.isEIP1559 && chainId != null) {
    final encodedTx = LengthTrackingByteSink();
    encodedTx.addByte(0x02);
    encodedTx.add(rlp
        .encode(_encodeEIP1559ToRlp(transaction, null, BigInt.from(chainId))));

    encodedTx.close();
    final signature = await c.signToSignature(encodedTx.asBytes(),
        chainId: chainId, isEIP1559: transaction.isEIP1559);

    return uint8ListFromList(rlp.encode(
        _encodeEIP1559ToRlp(transaction, signature, BigInt.from(chainId))));
  }
  final innerSignature =
      chainId == null ? null : MsgSignature(BigInt.zero, BigInt.zero, chainId);

  final encoded =
      uint8ListFromList(rlp.encode(_encodeToRlp(transaction, innerSignature)));
  final signature = await c.signToSignature(encoded, chainId: chainId);

  return uint8ListFromList(rlp.encode(_encodeToRlp(transaction, signature)));
}

List<dynamic> _encodeEIP1559ToRlp(
    Transaction transaction, MsgSignature? signature, BigInt chainId) {
  final list = [
    chainId,
    transaction.nonce,
    transaction.maxPriorityFeePerGas!.getInWei,
    transaction.maxFeePerGas!.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.addressBytes);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  list.add([]); // access list

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}

List<dynamic> _encodeToRlp(Transaction transaction, MsgSignature? signature) {
  final list = [
    transaction.nonce,
    transaction.gasPrice?.getInWei,
    transaction.maxGas,
  ];

  if (transaction.to != null) {
    list.add(transaction.to!.addressBytes);
  } else {
    list.add('');
  }

  list
    ..add(transaction.value?.getInWei)
    ..add(transaction.data);

  if (signature != null) {
    list
      ..add(signature.v)
      ..add(signature.r)
      ..add(signature.s);
  }

  return list;
}
