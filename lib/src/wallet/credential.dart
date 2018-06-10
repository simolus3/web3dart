import 'dart:math';

import 'package:meta/meta.dart';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:web3dart/src/utils/crypto.dart' as crypto;

/// Holds information about an address in Ethereum.
@immutable
class EthereumAddress {

  static const int _ethAddLenBytes = 20;

  /// The number associated with the address
  final BigInt number;

  /// Creates an Ethereum Address from a string containing its hexadecimal 
  /// representation, optionally with an "0x" prefix.
  EthereumAddress(String hex) : this.fromNumber(numbers.hexToInt(hex));

  /// Creates an address from its number
  const EthereumAddress.fromNumber(this.number);

  /// Creates an address from the public key
  EthereumAddress.fromPublicKey(BigInt publicKey):
    number = _publicKeyToAddressNum(publicKey);

  /// Returns this address in a hexadecimal representation, with 0x prefixed
  String get hex => numbers.toHex(number, pad: true, 
    forcePadLen: _ethAddLenBytes * 2, include0x: true);
  
  /// Returns this address in a hexadecimal representation, without any prefix
  String get hexNo0x => numbers.toHex(number, pad: true, 
    forcePadLen: _ethAddLenBytes * 2, include0x: false);

  @override
  String toString() => hex;

  static BigInt _publicKeyToAddressNum(BigInt public) {
    var addressBytes = crypto.publicKeyToAddress(numbers.intToBytes(public));
    return numbers.bytesToInt(addressBytes);
  }

}

/// Credentials are used to sign messages and transactions, so that Ethereum
/// nodes can verify messages are coming from the account sending them.
@immutable
class Credentials {

  final BigInt privateKey;
  final BigInt publicKey;
  
  final EthereumAddress address;

  const Credentials._(this.privateKey, this.publicKey, this.address);

  /// Creates credentials by random. Useful to set up a new Ethereum address.
  /// When calling this method, make sure to use a cryptographically safe
  /// number generator.
  static Credentials createRandom(Random random) {
    var private = crypto.generateNewPrivateKey(random);
    return fromPrivateKey(private);
  }

  /// Constructs a new set of credentials from the hex representation of the
  /// private key, which may be prefixed with "0x". The public key and the
  /// corresponding address will be derived.
  static Credentials fromPrivateKeyHex(String privateKey) {
    return fromPrivateKey(numbers.hexToInt(privateKey));
  }

  /// Constructs a new set of credentials from the private key. The public key
  /// and the corresponding address will be derived.
  static Credentials fromPrivateKey(BigInt privateKey) {
    var publicKey = _privateKeyToPublic(privateKey);
    var address = new EthereumAddress.fromPublicKey(publicKey);

    return new Credentials._(privateKey, publicKey, address);
  }

  static BigInt _privateKeyToPublic(BigInt private) {
    var privateKeyBytes = numbers.numberToBytes(private);
    var publicKeyBytes = crypto.privateKeyToPublic(privateKeyBytes);

    return numbers.bytesToInt(publicKeyBytes);
  }

}