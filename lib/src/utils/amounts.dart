import 'package:bignum/bignum.dart';

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

	static final Map<EtherUnit, BigInteger> FACTORS = {
		EtherUnit.WEI: BigInteger.ONE,
		EtherUnit.KWEI: new BigInteger(10).pow(3),
		EtherUnit.MWEI: new BigInteger(10).pow(6),
		EtherUnit.GWEI: new BigInteger(10).pow(9),
		EtherUnit.SZABO: new BigInteger(10).pow(12),
		EtherUnit.FINNEY: new BigInteger(10).pow(15),
		EtherUnit.ETHER: new BigInteger(10).pow(18)
	};

	final BigInteger _value;

	BigInteger get getInWei => _value;
	BigInteger get getInEther => getValueInUnitBI(EtherUnit.ETHER);

	const EtherAmount.inWei(this._value);

	EtherAmount.zero() : this.inWei(BigInteger.ZERO);

	/// Constructs an amount of Ether by a unit and its amount. [amount] can either
	/// be a base10 string, a num, or a BigInteger.
	static EtherAmount fromUnitAndValue(EtherUnit unit, dynamic amount) {
		if (!(amount is BigInteger))
			amount = new BigInteger(amount);

		return new EtherAmount.inWei(amount.multiply(FACTORS[unit]));
	}

	/// Gets the value of this amount in the specified unit as a whole number.
	/// **WARNING**: For all units except for [EtherUnit.WEI], this method will
	/// discard the remainder occurring in the division, making it unsuitable for
	/// calculations or storage. You should store and process amounts of ether by
	/// using a BigInteger storing the amount in wei.
	BigInteger getValueInUnitBI(EtherUnit unit) => _value.divide(FACTORS[unit]);

	/// Gets the value of this amount in the specified unit. **WARNING**: Due to
	/// rounding errors, the return value of this function is not reliable,
	/// especially for larger amounts or smaller units. While it can be used to
	/// display the amount of ether in a human-readable format, it should not be
	/// used for anything else.
	num getValueInUnit(EtherUnit unit) {
		var data = _value.divideAndRemainder(FACTORS[unit]);

		var value = data[0];
		var remainder = data[1];

		return value.intValue() + remainder.intValue() / FACTORS[unit].intValue();
	}
}