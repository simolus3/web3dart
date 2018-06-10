enum EtherUnit {
	///Wei, the smallest and atomic amount of Ether
	wei,
	///kwei, 1000 wei
	kwei,
	///Mwei, one million wei
	mwei,
	///Gwei, one billion wei. Typically a reasonable unit to measure gas prices.
	gwei,

	///szabo, 10^12 wei or 1 μEther
	szabo,
	///finney, 10^15 wei or 1 mEther
	finney,

	ether
}

/// Utility class to easily convert amounts of Ether into different units of
/// quantities.
class EtherAmount {

	static final Map<EtherUnit, BigInt> factors = {
		EtherUnit.wei: BigInt.one,
		EtherUnit.kwei: new BigInt.from(10).pow(3),
		EtherUnit.mwei: new BigInt.from(10).pow(6),
		EtherUnit.gwei: new BigInt.from(10).pow(9),
		EtherUnit.szabo: new BigInt.from(10).pow(12),
		EtherUnit.finney: new BigInt.from(10).pow(15),
		EtherUnit.ether: new BigInt.from(10).pow(18)
	};

	final BigInt _value;

	BigInt get getInWei => _value;
	BigInt get getInEther => getValueInUnitBI(EtherUnit.ether);

	const EtherAmount.inWei(this._value);

	EtherAmount.zero() : this.inWei(BigInt.zero);

	/// Constructs an amount of Ether by a unit and its amount. [amount] can either
	/// be a base10 string, an int, or a BigInt.
	static EtherAmount fromUnitAndValue(EtherUnit unit, dynamic amount) {
		BigInt parsedAmount;
    
    if (amount is BigInt) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = new BigInt.from(amount);
    } else if (amount is String) {
      parsedAmount = new BigInt.from(int.parse(amount));
    } else {
      throw ArgumentError("Invalid type, must be BigInt, string or int");
    }

		return new EtherAmount.inWei(parsedAmount * factors[unit]);
	}

	/// Gets the value of this amount in the specified unit as a whole number.
	/// **WARNING**: For all units except for [EtherUnit.wei], this method will
	/// discard the remainder occurring in the division, making it unsuitable for
	/// calculations or storage. You should store and process amounts of ether by
	/// using a BigInt storing the amount in wei.
	BigInt getValueInUnitBI(EtherUnit unit) => _value ~/ factors[unit];

	/// Gets the value of this amount in the specified unit. **WARNING**: Due to
	/// rounding errors, the return value of this function is not reliable,
	/// especially for larger amounts or smaller units. While it can be used to
	/// display the amount of ether in a human-readable format, it should not be
	/// used for anything else.
	num getValueInUnit(EtherUnit unit) {
    var value = _value ~/ factors[unit];
    var remainder = _value.remainder(factors[unit]);

		return value.toInt() + (remainder.toInt() / factors[unit].toInt());
	}
}