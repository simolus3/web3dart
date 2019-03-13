part of 'package:web3dart/credentials.dart';

/// Represents an Ethereum address.
@immutable
class EthereumAddress {
  static final RegExp _basicAddress =
      RegExp(r'^(0x)?[0-9a-f]{40}', caseSensitive: false);

  final Uint8List _addressBytes;

  /// An ethereum address from the raw address bytes.
  EthereumAddress(this._addressBytes) : assert(_addressBytes.length == 20);

  /// Constructs an Ethereum address from a public key. The address is formed by
  /// the last 20 bytes of the keccak hash of the public key.
  factory EthereumAddress.fromPublicKey(Uint8List publicKey) {
    return EthereumAddress(publicKeyToAddress(publicKey));
  }

  /// Parses an Ethereum address from the hexadecimal representation. The
  /// representation must have a length of 20 bytes (or 40 hexadecimal chars),
  /// and can optionally be prefixed with "0x".
  ///
  /// If [enforceEip55] is true or the address has both uppercase and lowercase
  /// chars, the address must be valid according to [EIP 55](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md).
  factory EthereumAddress.fromString(String hex, {bool enforceEip55 = false}) {
    if (!_basicAddress.hasMatch(hex)) {
      throw ArgumentError.value(hex, 'address',
          'Must be a hex string with a length of 40, optionally prefixed with "0x"');
    }

    if (!enforceEip55 &&
        (hex.toUpperCase() == hex || hex.toLowerCase() == hex)) {
      return EthereumAddress(hexToBytes(hex));
    }

    // Validates as of EIP 55, https://ethereum.stackexchange.com/a/1379
    final address = strip0x(hex);
    final hash = bytesToHex(keccakAscii(address.toLowerCase()));
    for (var i = 0; i < 40; i++) {
      // the nth letter should be uppercase if the nth digit of casemap is 1
      final hashedPos = int.parse(hash[i], radix: 16);
      if ((hashedPos > 7 && address[i].toUpperCase() != address[i]) ||
          (hashedPos <= 7 && address[i].toLowerCase() != address[i])) {
        throw ArgumentError('Address has invalid case-characters and is'
            'thus not EIP-55 conformant, rejecting. Address was: $hex');
      }
    }

    return EthereumAddress(hexToBytes(hex));
  }

  /// A hexadecimal representation of this address, padded to a length of 40
  /// characters or 20 bytes, and prefixed with "0x".
  String get hex =>
      bytesToHex(_addressBytes, include0x: true, forcePadLength: 40);

  /// A hexadecimal representation of this address, padded to a length of 40
  /// characters or 20 bytes, but not prefixed with "0x".
  String get hexNo0x =>
      bytesToHex(_addressBytes, include0x: false, forcePadLength: 40);

  /// Returns this address in a hexadecimal representation, like with [hex].
  /// The hexadecimal characters A-F in the address will be in lower- or
  /// uppercase depending on [EIP 55](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md).
  String get hexEip55 {
    // https://eips.ethereum.org/EIPS/eip-55#implementation
    final hex = hexNo0x.toLowerCase();
    final hash = bytesToHex(keccakAscii(hexNo0x));

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

  @override
  String toString() => hex;

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        (other is EthereumAddress && other.hex == hex);
  }

  @override
  int get hashCode {
    return hex.hashCode;
  }
}
