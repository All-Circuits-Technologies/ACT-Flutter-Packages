// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math';

/// Contains utility methods to help the management of cryptography
sealed class CryptoUtility {
  /// Contains all the alpha numeric characters
  static const _alphaNumericChars =
      "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890";

  /// Contains a list of special characters
  static const _specialChars = "!@#\$%^*";

  /// Contains all the alpha numeric characters + some special characters [_specialChars]
  static const _alphaNumericAndSpecialChars = "$_alphaNumericChars$_specialChars";

  /// Get a random string with the given [length].
  ///
  /// If [addSpecialChars] is equals to true, the random string may contain some special characters
  ///
  /// The [Random.secure()] method is used to get random values
  static String getRandomString(
    int length, {
    bool addSpecialChars = false,
  }) {
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length,
        (_) => _getRandomChar(
              random: random,
              addSpecialChars: addSpecialChars,
            )));
  }

  /// Get random char from the given string
  static int _getRandomCharFromList(Random random, String charsList) =>
      charsList.codeUnitAt(random.nextInt(charsList.length));

  /// Get random char from the right list
  static int _getRandomChar({
    required Random random,
    required bool addSpecialChars,
  }) =>
      addSpecialChars
          ? _getRandomCharFromList(random, _alphaNumericAndSpecialChars)
          : _getRandomCharFromList(random, _alphaNumericChars);
}
