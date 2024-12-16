// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:intl/intl.dart';

/// Contains useful static functions around Intl class of intl package
abstract class IntlUtility {
  /// This text is a clearly invalid translation result used to detect translation issues.
  static const _obviouslyIllTranslation = "";

  /// Get a simple translated text using its translation key
  ///
  /// Returns null if translation is not found
  static String? getTranslationByKey(String key) {
    // This helpers deserves a few notes about Intl internals.
    //
    // Intl translations lookup basically works as follow (see `message_lookup_by_library.dart`):
    // - If a translation is found with wanted `name`, it is returned
    // - Otherwise, untranslated `messageText` is returned
    //
    // Core lookup tool is `messageLookup` member of `src/intl_helpers.dart` which is not exported
    // by intl package. It take nullable arguments and returns a nullable string (null is returned
    // if key is not found by its `name` and if `messageText` was given null).
    //
    // intl package exposes `Intl.message` API which relies on `messageLookup`, but which requires
    // a not-nullable `messageText` argument in order to have a not-nullable String return type.
    //
    // We better like private `messageLookup` spirit of returning null in our case, therefore we
    // somehow reimplement it by detecting our custom `messageText` result.
    final intlResult = Intl.message(_obviouslyIllTranslation, name: key);
    return intlResult == _obviouslyIllTranslation ? null : intlResult;
  }
}
