/// Library to interact with ethereum smart contracts. Handles encoding and
/// decoding of the solidity contact ABI and creating transactions for calls on
/// smart contracts.
library contracts;

import 'dart:typed_data';

import 'credentials.dart' show EthereumAddress;
import 'crypto.dart';
import 'src/utils/length_tracking_byte_sink.dart';

part 'src/contracts/abi/types.dart';
part 'src/contracts/abi/integers.dart';