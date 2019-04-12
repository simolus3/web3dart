/// Library to interact with ethereum smart contracts. Handles encoding and
/// decoding of the solidity contact ABI and creating transactions for calls on
/// smart contracts.
library contracts;

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'credentials.dart' show EthereumAddress;
import 'crypto.dart';
import 'src/utils/length_tracking_byte_sink.dart';
import 'src/utils/typed_data.dart';

part 'src/contracts/abi/abi.dart';
part 'src/contracts/abi/arrays.dart';
part 'src/contracts/abi/integers.dart';
part 'src/contracts/abi/tuple.dart';
part 'src/contracts/abi/types.dart';
