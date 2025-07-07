// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_logger_manager/act_logger_manager.dart';

/// Utility class to manage bytes
///
/// It contains the limits of signed and unsigned integer and also methods to manage LSB first bytes
abstract class ByteUtility {
  static const int _byteMask = 0xFF;
  static const int _nbOfBitsInByte = 8;

  /// The bytes number in an unsigned integer of 64bits
  static const int bytesNbUInt64 = 8;

  /// The bytes number in an unsigned integer of 32bits
  static const int bytesNbUInt32 = 4;

  /// The bytes number in an unsigned integer of 16bits
  static const int bytesNbUInt16 = 2;

  /// The bytes number in an unsigned integer of 8bits
  static const int bytesNbUInt8 = 1;

  /// The minimum value a signed integer of 8bits can have
  static const int minInt8 = -maxInt8 - 1;

  /// The maximum value a signed integer of 8bits can have
  static const int maxInt8 = 0x7F;

  /// The minimum value a signed integer of 16bits can have
  static const int minInt16 = -maxInt16 - 1;

  /// The maximum value a signed integer of 16bits can have
  static const int maxInt16 = 0x7FFF;

  /// The minimum value a signed integer of 32bits can have
  static const int minInt32 = -maxInt32 - 1;

  /// The maximum value a signed integer of 32bits can have
  static const int maxInt32 = 0x7FFFFFFF;

  /// The minimum value a signed integer of 64bits can have
  ///
  /// This is a BigInt, which is needed by the web platform. The web platform only supports integers
  /// with 32bits. In other platforms, integers are 64 bits.
  static final minInt64 = -maxInt64 - BigInt.one;

  /// The maximum value a signed integer of 64bits can have
  ///
  /// This is a BigInt, which is needed by the web platform. The web platform only supports integers
  /// with 32bits. In other platforms, integers are 64 bits.
  static final maxInt64 = BigInt.parse("0x7FFFFFFFFFFFFFFF");

  /// The minimum value an unsigned integer can have
  static const int minUInt = 0;

  /// The maximum value an unsigned integer of 8bits can have
  static const int maxUInt8 = 0xFF;

  /// The maximum value an unsigned integer of 16bits can have
  static const int maxUInt16 = 0xFFFF;

  /// The maximum value an unsigned integer of 32bits can have
  static const int maxUInt32 = 0xFFFFFFFF;

  /// Convert the given [number] to a LSB byte list
  ///
  /// Because in dart an integer is a signed 64bits, you have to gives the final [bytesNb] you want
  /// to get
  /// [isSigned] can be used to precise we store an unsigned value in the [number] given and we want
  /// to get an unsigned value in the returned list.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method verifies if what you ask is possible: if you don't ask an impossible thing to do.
  /// If a problem occurred null is returned.
  /// If you are sure of your parameters, you can use [unsafeConvertToLsbFirst] method
  static Uint8List? convertToLsbFirst({
    required int number,
    required int bytesNb,
    bool isSigned = true,
  }) {
    if (!ByteUtility.testNumberLimits(number: number, bytesNb: bytesNb, isSigned: isSigned)) {
      return null;
    }

    return unsafeConvertToLsbFirst(number: number, bytesNb: bytesNb, isSigned: isSigned);
  }

  /// Convert the given [number] to a LSB byte list
  ///
  /// Because in dart an integer is a signed 64bits, you have to gives the final [bytesNb] you want
  /// to get
  /// [isSigned] can be used to precise we store an unsigned value in the [number] given and we want
  /// to get an unsigned value in the returned list.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method doesn't verify the parameters you give. If your parameters are incoherent, the
  /// method may raise an exception or returns wrong values.
  /// If you want a check on your parameters use [convertToLsbFirst] method
  static Uint8List unsafeConvertToLsbFirst({
    required int number,
    required int bytesNb,
    bool isSigned = true,
  }) {
    final tmp = Uint8List(bytesNb);
    for (var idx = 0; idx < bytesNb; ++idx) {
      tmp[idx] = ByteUtility.unsafeGetByte(number, idx);
    }

    return tmp;
  }

  /// Convert the given [number] to a MSB byte list
  ///
  /// Because in dart an integer is a signed 64bits, you have to gives the final [bytesNb] you want
  /// to get
  /// [isSigned] can be used to precise we store an unsigned value in the [number] given and we want
  /// to get an unsigned value in the returned list.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits
  ///
  /// This method verifies if what you ask is possible: if you don't ask an impossible thing to do.
  /// If a problem occurred null is returned.
  /// If you are sure of your parameters, you can use [unsafeConvertToLsbFirst] method
  static Uint8List? convertToMsbFirst({
    required int number,
    required int bytesNb,
    bool isSigned = true,
  }) {
    if (!ByteUtility.testNumberLimits(number: number, bytesNb: bytesNb, isSigned: isSigned)) {
      return null;
    }

    return unsafeConvertToMsbFirst(number: number, bytesNb: bytesNb, isSigned: isSigned);
  }

  /// Convert the given [number] to a MSB byte list
  ///
  /// Because in dart an integer is a signed 64bits, you have to gives the final [bytesNb] you want
  /// to get
  /// [isSigned] can be used to precise we store an unsigned value in the [number] given and we want
  /// to get an unsigned value in the returned list.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method doesn't verify the parameters you give. If your parameters are incoherent, the
  /// method may raise an exception or returns wrong values.
  /// If you want a check on your parameters use [convertToLsbFirst] method
  static Uint8List unsafeConvertToMsbFirst({
    required int number,
    required int bytesNb,
    bool isSigned = true,
  }) {
    final tmp = Uint8List(bytesNb);
    for (var idx = 0; idx < bytesNb; ++idx) {
      tmp[idx] = ByteUtility.unsafeGetByte(number, (bytesNb - 1) - idx);
    }

    return tmp;
  }

  /// Get a byte in a [number] given thanks to the [byteIndex]
  /// The method doesn't verify if the byteIndex overflows the integer
  static int unsafeGetByte(int number, int byteIndex) {
    final bitIndex = byteIndex * ByteUtility._nbOfBitsInByte;
    return ((number & (ByteUtility._byteMask << bitIndex)) >> bitIndex);
  }

  /// Convert a byte list (stored in LSB first): [lsbNumber], to number
  ///
  /// [isSigned] is useful to know if the [lsbNumber] stores a signed or unsigned number.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method to get unsigned integer of 64bits.
  ///
  /// This method verifies if what you ask is possible: if you don't ask an impossible thing to do.
  /// If a problem occurred null is returned.
  /// If you are sure of your parameters, you can use [unsafeConvertFromLsb] method
  static int? convertFromLsb({
    required Uint8List lsbNumber,
    bool isSigned = true,
  }) {
    if (!_testConvertLimit(number: lsbNumber, isSigned: isSigned)) {
      // We can't manage an unsigned int
      return null;
    }

    return unsafeConvertFromLsb(lsbNumber: lsbNumber, isSigned: isSigned);
  }

  /// Convert a byte list (stored in LSB first): [lsbNumber], to number
  ///
  /// [isSigned] is useful to know if the [lsbNumber] stores a signed or unsigned number.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method doesn't verify the parameters you give. If your parameters are incoherent, the
  /// method may raise an exception or returns wrong values.
  /// If you want a check on your parameters use [convertFromLsb] method
  static int unsafeConvertFromLsb({
    required Uint8List lsbNumber,
    bool isSigned = true,
  }) {
    final lsbNumberLength = lsbNumber.length;
    var number = 0;

    for (var idx = 0; idx < lsbNumberLength; ++idx) {
      number |= (lsbNumber[idx] << (idx * ByteUtility._nbOfBitsInByte));
    }

    if (isSigned) {
      number = number.toSigned(lsbNumberLength * ByteUtility._nbOfBitsInByte);
    }

    return number;
  }

  /// Convert a byte list (stored in MSB first): [msbNumber], to number
  ///
  /// [isSigned] is useful to know if the [msbNumber] stores a signed or unsigned number.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method verifies if what you ask is possible: if you don't ask an impossible thing to do.
  /// If a problem occurred null is returned.
  /// If you are sure of your parameters, you can use [unsafeConvertFromMsb] method
  static int? convertFromMsb({
    required Uint8List msbNumber,
    bool isSigned = true,
  }) {
    if (!_testConvertLimit(number: msbNumber, isSigned: isSigned)) {
      // We can't manage an unsigned int
      return null;
    }

    return unsafeConvertFromMsb(msbNumber: msbNumber, isSigned: isSigned);
  }

  /// Convert a byte list (stored in MSB first): [msbNumber], to number
  ///
  /// [isSigned] is useful to know if the [msbNumber] stores a signed or unsigned number.
  /// Be careful: you can't store an unsigned integer 64bits in a signed integer; therefore this
  /// method can't be used for unsigned integer of 64bits.
  ///
  /// This method doesn't verify the parameters you give. If your parameters are incoherent, the
  /// method may raise an exception or returns wrong values.
  /// If you want a check on your parameters use [convertFromMsb] method
  static int unsafeConvertFromMsb({
    required Uint8List msbNumber,
    bool isSigned = true,
  }) {
    final msbNumberLength = msbNumber.length;
    var number = 0;

    for (var idx = 0; idx < msbNumberLength; ++idx) {
      number |= (msbNumber[idx] << (((msbNumberLength - 1) - idx) * ByteUtility._nbOfBitsInByte));
    }

    if (isSigned) {
      number = number.toSigned(msbNumberLength * ByteUtility._nbOfBitsInByte);
    }

    return number;
  }

  /// The method converts a list to Uint8List
  ///
  /// The default Uint8List fromList constructor truncates the int values contains in the
  /// List\<int\> to match an Uint8.
  ///
  /// This method test if the int values can be Uint8 or returns null if an overflow is detected
  static Uint8List? safeConvertList(
    List<int> values, {
    required LoggerManager loggerManager,
  }) {
    for (final value in values) {
      if (value < 0 || value > ByteUtility.maxUInt8) {
        loggerManager.w("The list given overflows the Uint8 size: $value");
        return null;
      }
    }

    return Uint8List.fromList(values);
  }

  /// Test the convert limits when try to convert a byte list to number
  ///
  /// Returns false if a problem occurred in the test
  static bool _testConvertLimit({
    required Uint8List number,
    bool isSigned = true,
  }) {
    final numberLength = number.length;

    if (numberLength != ByteUtility.bytesNbUInt8 &&
        numberLength != ByteUtility.bytesNbUInt16 &&
        numberLength != ByteUtility.bytesNbUInt32 &&
        numberLength != ByteUtility.bytesNbUInt64) {
      // We have the wrong number of bytes
      return false;
    }

    if (!isSigned && numberLength == ByteUtility.bytesNbUInt64) {
      // We can't manage an unsigned int
      return false;
    }

    return true;
  }

  /// The method tests if what you ask on the [number] given is possible or not
  static bool testNumberLimits({
    required int number,
    required int bytesNb,
    required bool isSigned,
  }) {
    if (bytesNb <= 0 || bytesNb > ByteUtility.bytesNbUInt64) {
      // The bytes nb isn't correct
      return false;
    }

    if (bytesNb == ByteUtility.bytesNbUInt64) {
      // We can't manage a uint64 with an int64
      // And we can't overflow a signed integer of 64 bits, because the number given is a signed
      // integer of 64 bits
      return isSigned;
    }

    var minLimit = 0;
    var maxLimit = 0;

    // We don't calculate the min and max number, to gain performance
    if (bytesNb == ByteUtility.bytesNbUInt8) {
      minLimit = isSigned ? ByteUtility.minInt8 : 0;
      maxLimit = isSigned ? ByteUtility.maxInt8 : ByteUtility.maxUInt8;
    } else if (bytesNb == ByteUtility.bytesNbUInt16) {
      minLimit = isSigned ? ByteUtility.minInt16 : 0;
      maxLimit = isSigned ? ByteUtility.maxInt16 : ByteUtility.maxUInt16;
    } else if (bytesNb == ByteUtility.bytesNbUInt32) {
      minLimit = isSigned ? ByteUtility.minInt32 : 0;
      maxLimit = isSigned ? ByteUtility.maxInt32 : ByteUtility.maxUInt32;
    }

    if (number < minLimit || number > maxLimit) {
      // We overflow the limit
      return false;
    }

    return true;
  }
}
