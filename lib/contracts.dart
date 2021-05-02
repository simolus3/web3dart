/// Library to interact with ethereum smart contracts. Handles encoding and
/// decoding of the solidity contact ABI and creating transactions for calls on
/// smart contracts.
library contracts;

export 'src/contracts/abi/abi.dart';
export 'src/contracts/abi/arrays.dart';
export 'src/contracts/abi/integers.dart';
export 'src/contracts/abi/tuple.dart';
export 'src/contracts/abi/types.dart' hide array;
export 'src/contracts/deployed_contract.dart';
export 'src/contracts/generated_contract.dart';
