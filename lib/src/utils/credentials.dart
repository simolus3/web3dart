import 'dart:math';

import "package:web3dart/src/utils/keys.dart" as crypto;
import "package:web3dart/src/utils/numbers.dart" as num;

/// Credentials are used to sign messages and transactions, so that Ethereum
/// nodes can verify messages are coming from the account sending them.
class Credentials {

	/// The private key, used to sign transactions
	final BigInt privateKey;
	/// The public key of an account. It can be created with the private key but
	/// not vice-versa.
	final BigInt publicKey;

	/// The address of this account. Use to [addressHex] for a format most commonly
	/// used to represent Ethereum addresses.
	final BigInt address;

	/// Returns the Ethereum address of this account.
	String get addressHex => num.toHex(address, include0x: true);

	Credentials._(this.privateKey, this.publicKey, this.address);

	/// Constructs the public key and the address from this private key.
	static Credentials fromPrivateKey(BigInt privateKey) {
		var publicKeyBytes = crypto.privateKeyToPublic(num.numberToBytes(privateKey));
		var addressBytes = crypto.publicKeyToAddress(publicKeyBytes);
		
		return new Credentials._(
				privateKey, num.bytesToInt(publicKeyBytes), num.bytesToInt(addressBytes)
		);
	}

	/// Constructs the public key and the address from this private key.
	static Credentials fromHexPrivateKey(String privateKey)
			=> Credentials.fromPrivateKey(num.hexToInt(privateKey));

	/// Generates a new keypair and Ethereum address.
	///
	/// You can optionally issue your own random instance which will be used to
	/// generate the numbers. By default, a Random.secure() instance will be used.
	static Credentials generateNew({Random random}) {
		var privateKey = crypto.generateNewPrivateKey(random ?? new Random.secure());

		return Credentials.fromPrivateKey(privateKey);
	}
}