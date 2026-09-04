// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// The path of the text the page reads, without the locale it is translated in.
const _path = "assets/texts/readme.md";

void main() {
  late FakeLogger logger;
  late FakeGlobalManager globalManager;

  setUp(() {
    logger = FakeLogger();
    globalManager = FakeGlobalManager.install(logger: logger);
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// Reads the text of [_path] from a page shown in [locale].
  Future<String?> aPageReading(WidgetTester tester, {required Locale locale}) async {
    late Future<String?> text;

    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            text = IntlFileUtility.loadTransAssetFileText(context, _path);

            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    return text;
  }

  group("IntlFileUtility.loadTransAssetFileText", () {
    testWidgets("reads the text translated in the locale of the page", (tester) async {
      FakeAssets.serve({"assets/texts/readme_fr_FR.md": "bonjour"});

      expect(await aPageReading(tester, locale: const Locale("fr", "FR")), "bonjour");
    });

    testWidgets("falls back on the text of the locale of the device", (tester) async {
      FakeAssets.serve({"assets/texts/readme_${Intl.systemLocale}.md": "hello"});

      expect(await aPageReading(tester, locale: const Locale("fr", "FR")), "hello");
    });

    testWidgets("reads nothing when the text is translated in no locale it knows", (tester) async {
      FakeAssets.serve({"assets/texts/readme_de_DE.md": "hallo"});

      expect(await aPageReading(tester, locale: const Locale("fr", "FR")), isNull);
    });

    testWidgets("warns for every text it could not read", (tester) async {
      FakeAssets.serve({});

      await aPageReading(tester, locale: const Locale("fr", "FR"));

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(2));
    });

    testWidgets("warns once when it falls back on the locale of the device", (tester) async {
      FakeAssets.serve({"assets/texts/readme_${Intl.systemLocale}.md": "hello"});

      await aPageReading(tester, locale: const Locale("fr", "FR"));

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });
}
