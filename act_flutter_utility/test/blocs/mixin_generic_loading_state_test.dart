// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_blocs.dart';

void main() {
  group("MixinGenericLoadingState.interactionsDisabled", () {
    test("leaves the interactions enabled when nothing is loading", () {
      expect(const FakeLoadingState().interactionsDisabled, isFalse);
    });

    test("disables the interactions while something is loading", () {
      expect(const FakeLoadingState(loading: true).interactionsDisabled, isTrue);
    });

    test("keeps the loading reason of a state which adds one of its own", () {
      expect(const FakeReadOnlyState(loading: true).interactionsDisabled, isTrue);
    });

    test("adds the reason of a state which has one of its own", () {
      expect(const FakeReadOnlyState(readOnly: true).interactionsDisabled, isTrue);
    });
  });

  group("MixinGenericLoadingState.anErrorOccurred", () {
    test("reports no error by default", () {
      expect(const FakeLoadingState().anErrorOccurred, isFalse);
    });

    test("reports the error the state was built with", () {
      expect(const FakeLoadingState(anErrorOccurred: true).anErrorOccurred, isTrue);
    });
  });
}
