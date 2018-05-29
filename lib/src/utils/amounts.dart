enum EtherUnit {
	///Wei, the smallest and atomic amount of Ether
	WEI,
	///kwei, 1000 wei
	KWEI,
	///Mwei, one million wei
	MWEI,
	///Gwei, one billion wei. Typically a reasonable unit to measure gas prices.
	GWEI,

	///szabo, 10^12 wei or 1 μEther
	SZABO,
	///finney, 10^15 wei or 1 mEther
	FINNEY,

	ETHER
}

/// Utility class to easily convert amounts of Ether into different units of
/// quantities.
class EtherAmount {

	static final Map<EtherUnit, BigInt> FACTORS = {
		EtherUnit.WEI: BigInt.one,
		EtherUnit.KWEI: new BigInt.from(10).pow(3),
		EtherUnit.MWEI: new BigInt.from(10).pow(6),
		EtherUnit.GWEI: new BigInt.from(10).pow(9),
		EtherUnit.SZABO: new BigInt.from(10).pow(12),
		EtherUnit.FINNEY: new BigInt.from(10).pow(15),
		EtherUnit.ETHER: new BigInt.from(10).pow(18)
	};

	final BigInt _value;

	BigInt get getInWei => _value;
	BigInt get getInEther => getValueInUnitBI(EtherUnit.ETHER);

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

		return new EtherAmount.inWei(parsedAmount * FACTORS[unit]);
	}

	/// Gets the value of this amount in the specified unit as a whole number.
	/// **WARNING**: For all units except for [EtherUnit.WEI], this method will
	/// discard the remainder occurring in the division, making it unsuitable for
	/// calculations or storage. You should store and process amounts of ether by
	/// using a BigInt storing the amount in wei.
	BigInt getValueInUnitBI(EtherUnit unit) => _value ~/ FACTORS[unit];

	/// Gets the value of this amount in the specified unit. **WARNING**: Due to
	/// rounding errors, the return value of this function is not reliable,
	/// especially for larger amounts or smaller units. While it can be used to
	/// display the amount of ether in a human-readable format, it should not be
	/// used for anything else.
	num getValueInUnit(EtherUnit unit) {
    var value = _value ~/ FACTORS[unit];
    var remainder = _value.remainder(FACTORS[unit]);

		return value.toInt() + (remainder.toInt() / FACTORS[unit].toInt());
	}
}