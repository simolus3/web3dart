import 'dart:async';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String _CRYPTO_KITTIES_ABI_EXTRACT = '[{"constant":true,"inputs":[{"name":"_id","type":"uint256"}],"name":"getKitty","outputs":[{"name":"isGestating","type":"bool"},{"name":"isReady","type":"bool"},{"name":"cooldownIndex","type":"uint256"},{"name":"nextActionAt","type":"uint256"},{"name":"siringWithId","type":"uint256"},{"name":"birthTime","type":"uint256"},{"name":"matronId","type":"uint256"},{"name":"sireId","type":"uint256"},{"name":"generation","type":"uint256"},{"name":"genes","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]';
const String _PRIVATE_KEY = "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";

const String _URL = "https://api.myetherapi.com/eth"; //Use infura or own client for faster requests
const String _KITTY_ADDRESS = "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d";

class CryptoKitty {

	final int id;

	bool isGestating;
	bool isReady;

	/// Set to the ID of the sire cat for matrons that are pregnant,
	/// zero otherwise. A non-zero value here is how we know a cat
	/// is pregnant. Used to retrieve the genetic material for the new
	/// kitten when the birth transpires.
	int siringWithId;
	/// The timestamp from the block when this cat came into existence.
	DateTime birthTime;

	/// The ID of the parents of this kitty, set to 0 for gen0 cats.
	/// Note that using 32-bit unsigned integers limits us to a "mere"
	/// 4 billion cats. This number might seem small until you realize
	/// that Ethereum currently has a limit of about 500 million
	/// transactions per year! So, this definitely won't be a problem
	/// for several years (even as Ethereum learns to scale).
	int matronId, sireId;

	/// The "generation number" of this cat. Cats minted by the CK contract
	/// for sale are called "gen0" and have a generation number of 0. The
	/// generation number of all other cats is the larger of the two generation
	/// numbers of their parents, plus one.
	/// (i.e. max(matron.generation, sire.generation) + 1)
	int generation;

	/// The Kitty's genetic code is packed into these 256-bits, the format is
	/// sooper-sekret! A cat's genes never change.
	int genes;

	CryptoKitty.fromResponse(this.id, dynamic data) {
		this.isGestating = data[0];
		this.isReady = data[1];

		this.siringWithId = data[4];
		this.birthTime= new DateTime.fromMillisecondsSinceEpoch(data[5] * 1000);
		this.matronId = data[7];
		this.sireId = data[6];
		this.generation = data[8];
		this.genes = data[9];
	}

	@override
	String toString() {
		var gestating = (isGestating ? "" : "not ") + "gestating, matron is #$matronId";
		var ready = (isReady ? "" : "not ") + "ready";

		return "CryptoKitten #$id, born at $birthTime: $gestating; $ready " +
			"parents: matron = #$matronId, sire: $sireId, generation: $generation " +
			"genes: $genes";
	}
}

Future main() async {
	var httpClient = new Client();
	var ethClient = new Web3Client(_URL, httpClient);
	var credentials = Credentials.fromPrivateKeyHex(_PRIVATE_KEY);

	var kittiesABI = ContractABI.parseFromJSON(_CRYPTO_KITTIES_ABI_EXTRACT, "CryptoKittens");
	var kittiesContract = new DeployedContract(kittiesABI, new EthereumAddress(_KITTY_ADDRESS), ethClient, credentials);

	var getKittyFn = kittiesContract.findFunctionsByName("getKitty").first;

	var mrsWikiLeaksId = 363461;

	var kittenResponse = await new Transaction(keys: credentials, maximumGas: 0)
			.prepareForCall(kittiesContract, getKittyFn, [mrsWikiLeaksId])
			.call(ethClient);

	var kitty = new CryptoKitty.fromResponse(mrsWikiLeaksId, kittenResponse);
	print(kitty);
}