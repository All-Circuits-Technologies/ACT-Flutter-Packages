// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

/// An authentication service which records the terms the user accepted.
class _AcceptingService extends FakeAuthService with MixinTermsAcceptor {
  /// The version the service was asked to record, null as long as it was asked nothing.
  String? acceptedVersion;

  /// {@macro act_shared_auth.MixinTermsAcceptor.acceptTerms}
  @override
  Future<bool> acceptTerms({required String version}) async {
    acceptedVersion = version;

    return true;
  }
}

void main() {
  group("MixinTermsAcceptor", () {
    test("is told apart from a service which can't record the terms", () {
      final MixinAuthService accepting = _AcceptingService();
      final MixinAuthService plain = FakeAuthService();

      expect(accepting, isA<MixinTermsAcceptor>());
      expect(plain, isNot(isA<MixinTermsAcceptor>()));
    });

    test("hands the version the user saw over", () async {
      final service = _AcceptingService();

      expect(await service.acceptTerms(version: "2026-09-16"), isTrue);
      expect(service.acceptedVersion, "2026-09-16");
    });
  });
}
