// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' as math;

import 'package:act_dart_utility/src/utilities/byte_utility.dart';
import 'package:act_foundation/act_foundation.dart';

/// Contains useful methods to extend the management of numbers
sealed class NumUtility {
  /// This method converts a double to int8 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToInt8(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) => _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt8, true, logger: logger);

  /// This method converts a double to int16 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToInt16(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt16, true, logger: logger);

  /// This method converts a double to int32 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToInt32(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt32, true, logger: logger);

  /// This method converts a double to int64 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToInt64(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt64, true, logger: logger);

  /// This method converts a double to uInt8 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToUInt8(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt8, false, logger: logger);

  /// This method converts a double to uInt16 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToUInt16(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt16, false, logger: logger);

  /// This method converts a double to uInt32 and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? convertDoubleToUInt32(
    double value,
    int powerOfTenCoeff, {
    required MixinActLogger logger,
  }) =>
      _convertDoubleToInt(value, powerOfTenCoeff, ByteUtility.bytesNbUInt32, false, logger: logger);

  /// This method converts a double to integer and applied a power of ten factor to the double in
  /// order to keep the digits after comma in the integer.
  ///
  /// This is useful when you want to send number with digits to a device which doesn't support
  /// float or double.
  ///
  /// This method is only useful if you want to apply a power of then on the [value] before getting
  /// the integer value. If you only want to truncate the value, use [double.toInt] method.
  ///
  /// Returns null if a problem occurred
  static int? _convertDoubleToInt(
    double value,
    int powerOfTenCoeff,
    int bytesNb,
    bool isSigned, {
    required MixinActLogger logger,
  }) {
    if (!value.isFinite) {
      logger.w("We can't convert a not finite double to an integer");
      return null;
    }

    final newValue = value * math.pow(10, powerOfTenCoeff);
    if (!newValue.isFinite) {
      logger.w("We can't convert a double which is not finite: $value");
      return null;
    }

    // It's relevant to test newValue against a BigInt because newValue is a double; therefore,
    // there will be an approximation.
    final bigIntValue = BigInt.from(newValue);
    if (bigIntValue > ByteUtility.maxInt64 || bigIntValue < ByteUtility.minInt64) {
      logger.w(
        "We can't convert a double which is outside the range of an int64; the "
        "given value: $value, the power of ten: $powerOfTenCoeff",
      );
      return null;
    }

    final intValue = newValue.toInt();

    if (!ByteUtility.testNumberLimits(number: intValue, bytesNb: bytesNb, isSigned: isSigned)) {
      logger.w(
        "The double given: $value (with power of ten: $powerOfTenCoeff), can't be "
        "set into an integer with bytes number: $bytesNb, and which is signed: $isSigned",
      );
      return null;
    }

    return intValue;
  }
}
