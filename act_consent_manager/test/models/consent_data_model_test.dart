// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_consent.dart';

/// What the user agreed to in the version [version].
ConsentDataModel<FakeOptions> _data({
  String? version = "v2",
  ConsentStateEnum mandatory = ConsentStateEnum.accepted,
  ConsentStateEnum optional = ConsentStateEnum.accepted,
}) => ConsentDataModel<FakeOptions>(
  version: version,
  options: ConsentOptionsModel<FakeOptions>(
    options: {FakeOptions.mandatory: mandatory, FakeOptions.optional: optional},
  ),
);

void main() {
  group("ConsentDataModel.init", () {
    test("starts a user who agreed to nothing from what is refused", () {
      final data = ConsentDataModel<FakeOptions>.init(values: FakeOptions.values);

      expect(data.version, isNull);
      expect(data.options.getOptionState(FakeOptions.mandatory), ConsentStateEnum.notAccepted);
      expect(data.options.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });
  });

  group("ConsentDataModel.merge", () {
    test("takes the version and the answers of the data it is given", () {
      final data = ConsentDataModel<FakeOptions>.init(values: FakeOptions.values);

      final merged = data.merge(other: _data());

      expect(merged.version, "v2");
      expect(merged.options.getOptionState(FakeOptions.mandatory), ConsentStateEnum.accepted);
    });

    test("keeps its own answer on an option the other says nothing about", () {
      final data = _data(optional: ConsentStateEnum.notAccepted);

      final merged = data.merge(
        other: const ConsentDataModel<FakeOptions>(
          version: "v3",
          options: ConsentOptionsModel<FakeOptions>(
            options: {FakeOptions.mandatory: ConsentStateEnum.accepted},
          ),
        ),
      );

      expect(merged.version, "v3");
      expect(merged.options.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });

    test("changes nothing when there is nothing to merge with", () {
      final data = _data();

      expect(data.merge(other: null), data);
    });
  });

  group("ConsentDataModel", () {
    test("is the same data as another one which holds the same answers", () {
      expect(_data(), _data());
    });

    test("is another data as soon as the version differs", () {
      expect(_data(), isNot(_data(version: "v1")));
    });
  });
}
