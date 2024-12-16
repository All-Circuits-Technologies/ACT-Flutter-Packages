// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' as math;

import 'package:act_dart_utility/src/byte_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt8,
        true,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt16,
        true,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt32,
        true,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt64,
        true,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt8,
        false,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt16,
        false,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) =>
      _convertDoubleToInt(
        value,
        powerOfTenCoeff,
        ByteUtility.bytesNbUInt32,
        false,
        loggerManager: loggerManager,
      );

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
    required LoggerManager loggerManager,
  }) {
    if (!value.isFinite) {
      loggerManager.w("We can't convert a not finite double to an integer");
      return null;
    }

    final newValue = value * math.pow(10, powerOfTenCoeff);

    if (!newValue.isFinite || newValue > ByteUtility.maxInt64) {
      loggerManager.w("We can't convert a double which is greater than the max value of an int64; "
          "the given value: $value, the power of ten: $powerOfTenCoeff");
      return null;
    }

    final intValue = newValue.toInt();

    if (!ByteUtility.testNumberLimits(intValue, bytesNb, isSigned)) {
      loggerManager.w("The double given: $value (with power of ten: $powerOfTenCoeff), can't be "
          "set into an integer with bytes number: $bytesNb, and which is signed: $isSigned");
      return null;
    }

    return intValue;
  }
}
