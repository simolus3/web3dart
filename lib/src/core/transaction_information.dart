part of 'package:web3dart/web3dart.dart';

class TransactionInformation {
  TransactionInformation.fromMap(Map<String, dynamic> map)
      : blockHash = map['blockHash'] as String,
        blockNumber = map['blockNumber'] != null
            ? BlockNum.exact(int.parse(map['blockNumber'] as String))
            : const BlockNum.pending(),
        from = EthereumAddress.fromHex(map['from'] as String),
        gas = int.parse(map['gas'] as String),
        gasPrice = EtherAmount.inWei(BigInt.parse(map['gasPrice'] as String)),
        hash = map['hash'] as String,
        input = hexToBytes(map['input'] as String),
        nonce = int.parse(map['nonce'] as String),
        to = map['to'] != null
            ? EthereumAddress.fromHex(map['to'] as String)
            : null,
        transactionIndex = map['transactionIndex'] != null
            ? int.parse(map['transactionIndex'] as String)
            : null,
        value = EtherAmount.inWei(BigInt.parse(map['value'] as String)),
        v = int.parse(map['v'] as String),
        r = hexToInt(map['r'] as String),
        s = hexToInt(map['s'] as String);

  /// The hash of the block containing this transaction. If this transaction has
  /// not been mined yet and is thus in no block, it will be `null`
  final String? blockHash;

  /// [BlockNum] of the block containing this transaction, or [BlockNum.pending]
  /// when the transaction is not part of any block yet.
  final BlockNum blockNumber;

  /// The sender of this transaction.
  final EthereumAddress from;

  /// How many units of gas have been used in this transaction.
  final int gas;

  /// The amount of Ether that was used to pay for one unit of gas.
  final EtherAmount gasPrice;

  /// A hash of this transaction, in hexadecimal representation.
  final String hash;

  /// The data sent with this transaction.
  final Uint8List input;

  /// The nonce of this transaction. A nonce is incremented per sender and
  /// transaction to make sure the same transaction can't be sent more than
  /// once.
  final int nonce;

  /// Address of the receiver. `null` when its a contract creation transaction
  final EthereumAddress? to;

  /// Integer of the transaction's index position in the block. `null` when it's
  /// pending.
  int? transactionIndex;

  /// The amount of Ether sent with this transaction.
  final EtherAmount value;

  /// A cryptographic recovery id which can be used to verify the authenticity
  /// of this transaction together with the signature [r] and [s]
  final int v;

  /// ECDSA signature r
  final BigInt r;

  /// ECDSA signature s
  final BigInt s;

  /// The ECDSA full signature used to sign this transaction.
  MsgSignature get signature => MsgSignature(r, s, v);
}

class TransactionReceipt {
  TransactionReceipt(
      {required this.transactionHash,
      required this.transactionIndex,
      required this.blockHash,
      required this.cumulativeGasUsed,
      this.blockNumber = const BlockNum.pending(),
      this.contractAddress,
      this.status,
      this.from,
      this.to,
      this.gasUsed,
      this.logs = const []});

  TransactionReceipt.fromMap(Map<String, dynamic> map)
      : transactionHash = hexToBytes(map['transactionHash'] as String),
        transactionIndex = hexToDartInt(map['transactionIndex'] as String),
        blockHash = hexToBytes(map['blockHash'] as String),
        blockNumber = map['blockNumber'] != null
            ? BlockNum.exact(int.parse(map['blockNumber'] as String))
            : const BlockNum.pending(),
        from = map['from'] != null
            ? EthereumAddress.fromHex(map['from'] as String)
            : null,
        to = map['to'] != null
            ? EthereumAddress.fromHex(map['to'] as String)
            : null,
        cumulativeGasUsed = hexToInt(map['cumulativeGasUsed'] as String),
        gasUsed =
            map['gasUsed'] != null ? hexToInt(map['gasUsed'] as String) : null,
        contractAddress = map['contractAddress'] != null
            ? EthereumAddress.fromHex(map['contractAddress'] as String)
            : null,
        status = map['status'] != null
            ? (hexToDartInt(map['status'] as String) == 1)
            : null,
        logs = map['logs'] != null
            ? (map['logs'] as List<dynamic>)
                .map((log) => FilterEvent.fromMap(log as Map<String, dynamic>))
                .toList()
            : [];

  /// Hash of the transaction (32 bytes).
  final Uint8List transactionHash;

  /// Index of the transaction's position in the block.
  final int transactionIndex;

  /// Hash of the block where this transaction is in (32 bytes).
  final Uint8List blockHash;

  /// Block number where this transaction is in.
  final BlockNum blockNumber;

  /// Address of the sender.
  final EthereumAddress? from;

  /// Address of the receiver or `null` if it was a contract creation
  /// transaction.
  final EthereumAddress? to;

  /// The total amount of gas used when this transaction was executed in the
  /// block.
  final BigInt cumulativeGasUsed;

  /// The amount of gas used by this specific transaction alone.
  final BigInt? gasUsed;

  /// The address of the contract created if the transaction was a contract
  /// creation. `null` otherwise.
  final EthereumAddress? contractAddress;

  /// Whether this transaction was executed successfully.
  final bool? status;

  /// Array of logs generated by this transaction.
  final List<FilterEvent> logs;

  @override
  String toString() {
    return 'TransactionReceipt{transactionHash: ${bytesToHex(transactionHash)}, '
        'transactionIndex: $transactionIndex, blockHash: ${bytesToHex(blockHash)}, '
        'blockNumber: $blockNumber, from: ${from?.hex}, to: ${to?.hex}, '
        'cumulativeGasUsed: $cumulativeGasUsed, gasUsed: $gasUsed, '
        'contractAddress: ${contractAddress?.hex}, status: $status, logs: $logs}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionReceipt &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(transactionHash, other.transactionHash) &&
          transactionIndex == other.transactionIndex &&
          const ListEquality().equals(blockHash, other.blockHash) &&
          blockNumber == other.blockNumber &&
          from == other.from &&
          to == other.to &&
          cumulativeGasUsed == other.cumulativeGasUsed &&
          gasUsed == other.gasUsed &&
          contractAddress == other.contractAddress &&
          status == other.status &&
          const ListEquality().equals(logs, other.logs);

  @override
  int get hashCode =>
      transactionHash.hashCode ^
      transactionIndex.hashCode ^
      blockHash.hashCode ^
      blockNumber.hashCode ^
      from.hashCode ^
      to.hashCode ^
      cumulativeGasUsed.hashCode ^
      gasUsed.hashCode ^
      contractAddress.hashCode ^
      status.hashCode ^
      logs.hashCode;
}
