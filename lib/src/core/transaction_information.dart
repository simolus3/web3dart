part of 'package:web3dart/web3dart.dart';

class TransactionInformation {
  /// The hash of the block containing this transaction. If this transaction has
  /// not been mined yet and is thus in no block, it will be `null`
  final String blockHash;

  /// [BlockNum] of the block containing this transaction. `null` when it's
  /// pending
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
  final EthereumAddress to;

  /// Integer of the transaction's index position in the block. `null` when it's
  /// pending.
  int transactionIndex;

  /// The amount of Ether sent with this transaction.
  final EtherAmount value;

  /// A cryptographic recovery id which can be used to verify the authenticity
  /// of this transaction together with the signature [r] and [s]
  final int v;
  final Uint8List r;
  final Uint8List s;

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
        r = hexToBytes(map['r'] as String),
        s = hexToBytes(map['s'] as String);
}

class TransactionReceipt {
  /// Hash of the transaction (32 bytes).
  final Uint8List transactionHash;

  /// Index of the transaction's position in the block.
  final int transactionIndex;

  /// Hash of the block where this transaction is in (32 bytes).
  final Uint8List blockHash;

  /// Block number where this transaction is in.
  final BlockNum blockNumber;

  /// Address of the sender.
  final EthereumAddress from;

  /// Address of the receiver or `null` if it was a contract creation
  /// transaction.
  final EthereumAddress to;

  /// The total amount of gas used when this transaction was executed in the
  /// block.
  final BigInt cumulativeGasUsed;

  /// The amount of gas used by this specific transaction alone.
  final BigInt gasUsed;

  /// The address of the contract created if the transaction was a contract
  /// creation. `null` otherwise.
  final EthereumAddress contractAddress;

  /// Whether this transaction was executed successfully.
  final bool status;

  TransactionReceipt.fromJson(Map<String, dynamic> map)
      : transactionHash = hexToBytes(map['transactionHash'] as String),
        transactionIndex = hexToDartInt(map['transactionIndex'] as String),
        blockHash = hexToBytes(map['blockHash'] as String),
        blockNumber = map['blockNumber'] != null
            ? BlockNum.exact(int.parse(map['blockNumber'] as String))
            : const BlockNum.pending(),
        from = EthereumAddress.fromHex(map['from'] as String),
        to = map['to'] != null
            ? EthereumAddress.fromHex(map['to'] as String)
            : null,
        cumulativeGasUsed = hexToInt(map['cumulativeGasUsed'] as String),
        gasUsed = hexToInt(map['gasUsed'] as String),
        contractAddress = map['contractAddress'] != null
            ? EthereumAddress.fromHex(map['contractAddress'] as String)
            : null,
        status = hexToDartInt(map['status'] as String) == 1;
}
