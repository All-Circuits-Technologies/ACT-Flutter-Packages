// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_themes_app.dart';

void main() {
  group("AbsAppSpecificColors.getDisabledColor", () {
    test("keeps the color and makes it see through", () {
      const colors = FakeSpecificColors(highlight: Colors.amber);

      final disabled = colors.getDisabledColor(const Color(0xFF102030));

      expect(disabled, const Color(0x66102030));
    });
  });
}
