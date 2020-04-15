import 'package:web3dart/web3dart.dart';
import 'package:test/test.dart';

// https://iancoleman.io/bip39/
final mnemonicList = [
  {
    'auction skate real best plunge silly flush estate skate brick pumpkin glue':
        {
      "m/44'/60'/0'/0/0": '0xE8EB5B02328635FBAfEF7d6BCd8d86e5dA63c283',
      "m/44'/60'/0'/0/1": '0x7952c25457B71eE28ac0aff6f3aB7b0eD19C1f5F',
      "m/44'/60'/0'/0/9": '0x062F79711b7C74239f470834f106E074e394fE75',
    }
  },
  {
    'jewel moment slab destroy glass stereo valley outer pond link tissue food':
        {
      "m/44'/60'/0'/0/0": '0x5dC03E76bba14a1B0F76360EE3b8B082314cAf99',
      "m/44'/60'/0'/0/1": '0x1C4C094C4EDA3DCA8fE032544314f9C862B60F00',
      "m/44'/60'/0'/0/9": '0xf1F9B061C0738cDaf5FB1bb666F268eb922e5FA2',
    }
  },
  {
    'forward banana isolate still medal raise mushroom scatter luggage steak bleak taxi':
        {
      "m/44'/60'/0'/0/0": '0xcA750508dadFbe0A57CfCF702dCD06413Ed07b79',
      "m/44'/60'/0'/0/1": '0xFb88151f8aF555ee1985DaEBd3Fed7190C5e95D0',
      "m/44'/60'/0'/0/9": '0x41329c5F17847e48Bc8918f738185CB0fF43a746',
    }
  },
];

void main() {
  test('test bip32 bip39 bip44 use eip55', () async {
    for (final mnemonic in mnemonicList) {
      print('\nMnemonic: ${mnemonic.keys.first}');
      for (final derivePath in mnemonic.values.first.keys) {
        final ks = EthPrivateKey.fromMnemonic(mnemonic.keys.first,
            derivePath: derivePath);

        final address = await ks.extractAddress();

        print('DerivePath: "$derivePath" : Address: $address');

        expect(EthereumAddress.fromHex(mnemonic.values.first[derivePath]).hexEip55,
            address.hexEip55);
      }
    }
  });
}
