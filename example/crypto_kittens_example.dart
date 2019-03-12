import 'dart:async';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String cryptoKittensAbi =
    '[{"constant":true,"inputs":[{"name":"_id","type":"uint256"}],"name":"getKitty","outputs":[{"name":"isGestating","type":"bool"},{"name":"isReady","type":"bool"},{"name":"cooldownIndex","type":"uint256"},{"name":"nextActionAt","type":"uint256"},{"name":"siringWithId","type":"uint256"},{"name":"birthTime","type":"uint256"},{"name":"matronId","type":"uint256"},{"name":"sireId","type":"uint256"},{"name":"generation","type":"uint256"},{"name":"genes","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]';
const String privateKey =
    'c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3';

const String url =
    'https://api.myetherapi.com/eth'; //Use infura or own client for faster requests
const String kittyAddress = '0x06012c8cf97BEaD5deAe237070F9587f8E7A266d';

class CryptoKitty {
  final BigInt id;

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
    isGestating = data[0] as bool;
    isReady = data[1] as bool;

    siringWithId = data[4] as int;
    birthTime = DateTime.fromMillisecondsSinceEpoch(
        (data[5] as BigInt).toInt() * 1000);
    matronId = data[7] as int;
    sireId = data[6] as int;
    generation = data[8] as int;
    genes = data[9] as int;
  }

  @override
  String toString() {
    final gestating =
        '${(isGestating ? '' : 'not ')} gestating, matron is #$matronId';
    final ready = '${(isReady ? '' : 'not ')} ready';

    return 'CryptoKitten #$id, born at $birthTime: $gestating; $ready '
        'parents: matron = #$matronId, sire: $sireId, generation: $generation '
        'genes: $genes';
  }
}

Future main() async {
  final httpClient = Client();
  final ethClient = Web3Client(url, httpClient);
  final credentials = Credentials.fromPrivateKeyHex(privateKey);

  final kittiesABI =
      ContractABI.parseFromJSON(cryptoKittensAbi, 'CryptoKittens');
  final kittiesContract = DeployedContract(
      kittiesABI, EthereumAddress(kittyAddress), ethClient, credentials);

  final getKittyFn = kittiesContract.findFunctionsByName('getKitty').first;

  final mrsWikiLeaksId = BigInt.from(363461);

  final kittenResponse = await Transaction(keys: credentials, maximumGas: 0)
      .prepareForCall(
          kittiesContract, getKittyFn, [mrsWikiLeaksId]).call(ethClient);

  final kitty = CryptoKitty.fromResponse(mrsWikiLeaksId, kittenResponse);
  print(kitty);
}
