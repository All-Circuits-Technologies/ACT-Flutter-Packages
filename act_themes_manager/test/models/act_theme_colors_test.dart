// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_themes_manager/act_themes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_themes_app.dart';

/// The scheme of the colors of an application.
final _scheme = ColorScheme.fromSeed(seedColor: Colors.blue);

void main() {
  group("ActThemeColors", () {
    test("adds no color to the ones of the scheme when it was given none", () {
      expect(ActThemeColors<FakeSpecificColors>(colorScheme: _scheme).colorExtensions, isNull);
    });

    test("is the same colors as another one built from the same scheme", () {
      expect(
        ActThemeColors<FakeSpecificColors>(colorScheme: _scheme),
        ActThemeColors<FakeSpecificColors>(colorScheme: _scheme),
      );
    });

    test("is another colors as soon as the colors of the application differ", () {
      expect(
        ActThemeColors<FakeSpecificColors>(
          colorScheme: _scheme,
          colorExtensions: const FakeSpecificColors(highlight: Colors.amber),
        ),
        isNot(
          ActThemeColors<FakeSpecificColors>(
            colorScheme: _scheme,
            colorExtensions: const FakeSpecificColors(highlight: Colors.red),
          ),
        ),
      );
    });
  });
}
