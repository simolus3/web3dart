## 2.3.1

- Fix the `Web3Client.custom` constructor not setting all required fields.

## 2.3.0

- Support overloaded methods for generated contracts

## 2.2.0

- Add `EthPrivateKey.publicKey` getters
- Fix `window.ethereum` always being non-null, even if no provider is available

## 2.1.4

- Fix a generator crash for unexpected `devdoc` values

## 2.1.3

- Fix `EthPrivateKey.createRandom` sometimes failing

## 2.1.2

- Fix contract generation for events
- Don't generate a method for the fallback method
- Fix parsing contract abis in the presence of unknown function types

## 2.1.1

- Respect the `value` parameter in `estimateGas`

## 2.1.0

- Add `package:web3dart/browser.dart`, a library for using this package in
  Ethereum-enabled browsers.
- Add code generator for smart contracts. To use it, just put the generated abi
  json into a `.abi.json` file, add a dev-dependency on `build_runner` and run
  `(flutter | dart) pub run build_runner build`.
- Add the `package:web3dart/contracts/erc20.dart` library for interacting with an
  [ERC-20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md) smart contract.

## 2.0.0

- __Breaking__: Renamed `TransactionReceipt.fromJson` to `TransactionReceipt.fromMap`
- __Breaking__: Removed the `backgroundIsolate` option from `Web3Client`. 
  For background isolates, instead use `runner: await IsolateRunner.spawn()` from `package:isolate`.
- __Breaking__: Changed `TransactionInformation.r` and `TransactionInformation.s` from `Uint8List` to
  `BigInt`
- __Breaking__: When not setting the `maxGas` argument, this library will now estimate it instead of using
  a fixed upper bound.
- Migrate to null safety
- Add `ecRecover` and `isValidSignature` to verify messages. Thanks, [brickpop](https://github.com/brickpop)!
- Add `compressPublicKey` and `decompressPublicKey` to obtain a compressed or expanded version of keys.
- Add `getLogs` method to `Web3Client`. Thanks, [jmank88](https://github.com/jmank88)!
- Add `sendRawTransaction` to send a raw, signed transaction.
- Fix `hexToDartInt` not actually parsing hex ([#81](https://github.com/simolus3/web3dart/issues/81))
- Support for background isolates is temporarily disabled until `package:isolate` migrates to null safety

## 1.2.3

- include a `0x` for hex data in `eth_estimateGas` - thanks, [@Botary](https://github.com/Botary)

## 1.2.2
- Fixed a bug when decoding negative integers ([#73](https://github.com/simolus3/web3dart/issues/73))

## 1.2.0
- Added `estimateGas` method on `Web3Client` to estimate the amount of gas that
  would be used by a transaction.
  
In 1.2.1, the `atBlock` parameter on `estimateGas` was deprecated and will be ignored.

## 1.1.1, 1.1.1+1
- Fix parsing transaction receipts when the block number is not yet available.
Thanks to [@chart21](https://github.com/chart21) for the fix.
- Fix a typo that made it impossible to load the coinbase address. Thanks to
[@modulovalue](https://github.com/modulovalue) for the fix.

## 1.1.0
- Added `getTransactionReceipt` to get more detailed information about a
transaction, including whether it was executed successfully or not.

## 1.0.0
Basically a complete rewrite of the library - countless bug fixes, a more fluent
and consistent api and more features:
- experimental api to perform expensive operations in a background isolate. Set
`enableBackgroundIsolate` to true when creating a `Web3Client` to try it out.
- Events! Use `addedBlocks`, `pendingTransactions` and `events` for auto-updating
streams.
- The client now has a `dispose()` method which should be called to stop the 
background isolate and terminate all running streams.

This version contains breaking changes! Here is an overview listing some of them.

| Before        | Updated API  |
| :------------- | -----:|
| Creating credentials via `Credentials.fromPrivateKeyHex`   | Use the `EthPrivateKey` class or, even better, `client.credentialsFromPrivateKey` |
| Sending transactions or calling contract functions | The api has been changed to just a single methods instead of a transaction builder. See the examples for details. |
| Low-level cryptographic operations like signing, hashing and converting hex <-> byte array <-> integer  | Not available in the core library. Import `package:web3dart/crypto.dart` instead |

If you run into problems after updating, please [create an issue](https://github.com/simolus3/web3dart/issues/new).

## 0.4.4
 - Added `getTransactionByHash` method - thank you, [maxholman](https://github.com/maxholman)!
 - Allow a different N parameter for scrypt when creating new wallets.

## 0.4.0
 - New APIs allowing for a simpler access to wallets, credentials and addresses
 - More examples in the README

## 0.2.1
- More solidity types, not with encoding.

## 0.2
- Send transactions and call messages from smart contracts on the
  Blockchain.

## 0.1
- Create new Ethereum accounts

## 0.0.2
- Send and sign transactions

## 0.0.1

- Initial version, created by Stagehand
