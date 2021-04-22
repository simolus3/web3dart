import 'package:meta/meta.dart';

/// When the client is currently syncing its blockchain with the network, this
/// representation can be used to find information about at which block the node
/// was before the sync, at which node it currently is and at which block the
/// node will complete its sync.
class SyncInformation {
  /// The field represents the index of the block used in the synchronisation
  /// currently in progress.
  /// [startingBlock] is the block at which the sync started, [currentBlock] is
  /// the block that is currently processed and [finalBlock] is an estimate of
  /// the highest block number this synchronisation will contain.
  /// When the client is not syncing at the moment, these fields will be null
  /// and [isSyncing] will be false.
  final int? startingBlock, currentBlock, finalBlock;

  /// Indicates whether this client is currently syncing its blockchain with
  /// other nodes.
  bool get isSyncing => startingBlock != null;

  @internal
  SyncInformation(this.startingBlock, this.currentBlock, this.finalBlock);

  @override
  String toString() {
    if (isSyncing) {
      return 'SyncInformation: from $startingBlock to $finalBlock, '
          'current: $currentBlock';
    } else {
      return 'SyncInformation: Currently not performing a synchronisation';
    }
  }
}
