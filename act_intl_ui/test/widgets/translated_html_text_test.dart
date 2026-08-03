// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_intl_ui/act_intl_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_intl_ui.dart';

/// The path of the text the page of the tests displays, without the locale.
const _textPath = "assets/texts/terms.html";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  tearDown(FakeAssets.stop);

  /// Shows the page of an application which displays a translated text, in [locale].
  Future<void> aPage(WidgetTester tester, {Locale locale = const Locale("fr", "FR")}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: TranslatedHtmlText(textPath: _textPath, horizontalPadding: 8)),
      ),
    );
  }

  group("TranslatedHtmlText", () {
    testWidgets("displays the text of the locale the application is in", (tester) async {
      FakeAssets.serve({
        "assets/texts/terms_fr_FR.html": "<p>les conditions</p>",
        "assets/texts/terms_en_GB.html": "<p>the terms</p>",
      });

      await aPage(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Html), findsOneWidget);
      expect(tester.widget<Html>(find.byType(Html)).data, "<p>les conditions</p>");
    });

    testWidgets("displays the text of another locale of the application", (tester) async {
      FakeAssets.serve({
        "assets/texts/terms_fr_FR.html": "<p>les conditions</p>",
        "assets/texts/terms_en_GB.html": "<p>the terms</p>",
      });

      await aPage(tester, locale: const Locale("en", "GB"));
      await tester.pumpAndSettle();

      expect(tester.widget<Html>(find.byType(Html)).data, "<p>the terms</p>");
    });

    testWidgets("shows that it is loading until the text has been read", (tester) async {
      FakeAssets.serve({"assets/texts/terms_fr_FR.html": "<p>les conditions</p>"});

      await aPage(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Html), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets("says so when the text is translated in no locale of the application", (
      tester,
    ) async {
      FakeAssets.serve(const {});

      await aPage(tester);
      await tester.pumpAndSettle();

      expect(tester.widget<Html>(find.byType(Html)).data, "Cannot find a proper translation");
    });

    testWidgets("lets the user scroll a text which is longer than the page", (tester) async {
      FakeAssets.serve({
        "assets/texts/terms_fr_FR.html": "<p>${"les conditions " * 500}</p>",
      });

      await aPage(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(CupertinoScrollbar), findsOneWidget);
    });
  });
}
