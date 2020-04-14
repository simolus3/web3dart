import 'package:web3dart/web3dart.dart';

void main() async {

// https://iancoleman.io/bip39/
//
// auction skate real best plunge silly flush estate skate brick pumpkin glue
// 0xE8EB5B02328635FBAfEF7d6BCd8d86e5dA63c283
//
// jewel moment slab destroy glass stereo valley outer pond link tissue food
// 0x5dC03E76bba14a1B0F76360EE3b8B082314cAf99
//
// forward banana isolate still medal raise mushroom scatter luggage steak bleak taxi
// 0xcA750508dadFbe0A57CfCF702dCD06413Ed07b79

    final mnemonicList = [
        'auction skate real best plunge silly flush estate skate brick pumpkin glue',
        'jewel moment slab destroy glass stereo valley outer pond link tissue food',
        'forward banana isolate still medal raise mushroom scatter luggage steak bleak taxi',
    ];

    for ( final mnemonic in mnemonicList ) {

        final ks = EthPrivateKey.fromMnemonic(mnemonic);

        print('Mnemonic: $mnemonic');
        print("DerivePath: m/44'/60'/0'/0/0");
        print('Address: ${(await ks.extractAddress()).toString()}\n');

    }
}
