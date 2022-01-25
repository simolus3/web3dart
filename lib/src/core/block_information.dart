import 'package:web3dart/src/crypto/formatting.dart';
import 'package:web3dart/web3dart.dart';

class BlockInformation {
  final EtherAmount? baseFeePerGas;
  final DateTime timestamp;

  BlockInformation({
    required this.baseFeePerGas,
    required this.timestamp,
  });

  factory BlockInformation.fromJson(Map<String, dynamic> json) {
    return BlockInformation(
      baseFeePerGas: json.containsKey('baseFeePerGas')
          ? EtherAmount.fromUnitAndValue(
              EtherUnit.wei, hexToInt(json['baseFeePerGas'] as String))
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        hexToDartInt(json['timestamp'] as String) * 1000,
        isUtc: true,
      ),
    );
  }

  bool get isSupportEIP1559 => baseFeePerGas != null;
}
