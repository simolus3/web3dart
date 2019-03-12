import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web3dart/src/utils/numbers.dart' as numbers;
import 'package:web3dart/src/utils/crypto.dart' as crypto;

/// Holds information about an address in Ethereum.
@immutable
class EthereumAddress {
  static final RegExp basicAddress =
      RegExp(r'^(0x)?[0-9a-f]{40}', caseSensitive: false);

  static const int _ethAddLenBytes = 20;
  static final BigInt biggestAddress =
      (BigInt.one << (_ethAddLenBytes * 8)) - BigInt.one;

  /// The number associated with the address
  final BigInt number;

  /// Creates an Ethereum Address from a string containing its hexadecimal
  /// representation, optionally with an "0x" prefix.
  EthereumAddress(String hex) : this.fromNumber(_hexToAddressNum(hex));

  /// Creates an address from its number
  EthereumAddress.fromNumber(this.number) {
    if (number.isNegative)
      throw ArgumentError('Ethereum addresses must be positive');
    if (number > biggestAddress)
      throw ArgumentError(
          'Ethereum addresses must fit in $_ethAddLenBytes bytes');
  }

  /// Creates an address from the public key
  EthereumAddress.fromPublicKey(BigInt publicKey)
      : number = _publicKeyToAddressNum(publicKey);

  /// Returns this address in a hexadecimal representation, with 0x prefixed.
  String get hex => numbers.toHex(number,
      pad: true, forcePadLen: _ethAddLenBytes * 2, include0x: true);

  /// Returns a hexadecimal representation of this address with 0x prefixed.
  /// Additionally, the representation will use upper- or lowercase depending
  /// on the address reducing the probability of mistyping it.
  String get hexEip55 {
    // https://eips.ethereum.org/EIPS/eip-55#implementation
    final hex = hexNo0x.toLowerCase();
    final hash = numbers.bytesToHex(crypto.sha3(ascii.encode(hex)));

    final eip55 = StringBuffer('0x');
    for (var i = 0; i < hex.length; i++) {
      if (int.parse(hash[i], radix: 16) >= 8) {
        eip55.write(hex[i].toUpperCase());
      } else {
        eip55.write(hex[i]);
      }
    }

    return eip55.toString();
  }

  /// Returns this address in a hexadecimal representation, without any prefix
  String get hexNo0x => numbers.toHex(number,
      pad: true, forcePadLen: _ethAddLenBytes * 2, include0x: false);

  @override
  String toString() => hex;

  static BigInt _publicKeyToAddressNum(BigInt public) {
    final addressBytes = crypto.publicKeyToAddress(numbers.intToBytes(public));
    return numbers.bytesToInt(addressBytes);
  }

  static BigInt _hexToAddressNum(String hex) {
    // https://ethereum.stackexchange.com/a/1379

    if (!basicAddress.hasMatch(hex))
      throw ArgumentError('Not a valid Ethereum address (needs to be '
          'hexadecimal, 20 bytes and optionally prefixed with 0x): $hex');
    else if (hex.toUpperCase() == hex || hex.toLowerCase() == hex)
      // Either all lower or upper case => valid address, parse
      return numbers.hexToInt(hex);
    else {
      // Validate as of EIP 55
      final address = numbers.strip0x(hex);
      final hash =
          numbers.bytesToHex(crypto.sha3(ascii.encode(address.toLowerCase())));
      for (var i = 0; i < 40; i++) {
        // the nth letter should be uppercase if the nth digit of casemap is 1
        final hashedPos = int.parse(hash[i], radix: 16);
        if ((hashedPos > 7 && address[i].toUpperCase() != address[i]) ||
            (hashedPos <= 7 && address[i].toLowerCase() != address[i])) {
          throw ArgumentError('Address has invalid case-characters and is'
              'thus not EIP-55 conformant, rejecting. Address was: $hex');
        }
      }

      return numbers.hexToInt(hex);
    }
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
    final private = crypto.generateNewPrivateKey(random);
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
    if (privateKey < BigInt.one)
      throw ArgumentError('Private key must be positive (> 0)');
    if (privateKey >= crypto.params.n)
      throw ArgumentError('Private key must not exceed curve order');

    final publicKey = _privateKeyToPublic(privateKey);
    final address = EthereumAddress.fromPublicKey(publicKey);

    return Credentials._(privateKey, publicKey, address);
  }

  static BigInt _privateKeyToPublic(BigInt private) {
    final privateKeyBytes = Uint8List.fromList(numbers.numberToBytes(private));
    final publicKeyBytes = crypto.privateKeyToPublic(privateKeyBytes);

    return numbers.bytesToInt(publicKeyBytes);
  }
}
