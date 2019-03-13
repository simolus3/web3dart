part of 'package:web3dart/web3dart.dart';

/// For operations that are reading data from the blockchain without making a
/// transaction that would modify it, the Ethereum client can read that data
/// from previous states of the blockchain as well. This class specifies which
/// state to use.
class BlockNum {
  final bool useAbsolute;
  final int blockNum;

  const BlockNum._(this.useAbsolute, this.blockNum);

  bool get isPending => !useAbsolute && blockNum == 2;

  /// Use the state of the blockchain at the block specified.
  const BlockNum.exact(this.blockNum) : useAbsolute = true;

  /// Use the state of the blockchain with the first block
  const BlockNum.genesis()
      : useAbsolute = false,
        blockNum = 0;

  /// Use the state of the blockchain as of the latest mined block.
  const BlockNum.current()
      : useAbsolute = false,
        blockNum = 1;

  /// Use the current state of the blockchain, including pending transactions
  /// that have not yet been mined.
  const BlockNum.pending()
      : useAbsolute = false,
        blockNum = 2;

  /// Generates the block parameter as it is accepted by the Ethereum client.
  String toBlockParam() {
    if (useAbsolute) return '0x${blockNum.toRadixString(16)}';

    switch (blockNum) {
      case 0:
        return 'earliest';
      case 1:
        return 'latest';
      case 2:
        return 'pending';
      default:
        return 'latest'; //Can't happen, though
    }
  }
}
