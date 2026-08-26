// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_intl/act_intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
// The translations of an application are answered by a lookup which is only reachable from the
// internals of intl; a test which wants a translation to be found has to install one there.
// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';

/// The translations of the application under test.
class _Translations extends MessageLookupByLibrary {
  @override
  String get localeName => "en_US";

  @override
  Map<String, Object> get messages => {"aKey": () => "a translation"};
}

void main() {
  setUpAll(() {
    initializeInternalMessageLookup(CompositeMessageLookup.new);
    (messageLookup as CompositeMessageLookup).addLocale("en_US", (_) => _Translations());
  });

  group("IntlUtility.getTranslationByKey", () {
    test("gives back the translation of the key it is given", () {
      expect(IntlUtility.getTranslationByKey("aKey"), "a translation");
    });

    test("gives back nothing for a key which is not translated", () {
      expect(IntlUtility.getTranslationByKey("anotherKey"), isNull);
    });

    test("gives back nothing for a locale which has no translation at all", () {
      final translation = Intl.withLocale("fr_FR", () => IntlUtility.getTranslationByKey("aKey"));

      expect(translation, isNull);
    });
  });
}
