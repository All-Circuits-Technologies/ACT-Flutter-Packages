// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_consent.dart';

/// The options of a consent, with what the user answered on each of them.
ConsentOptionsModel<FakeOptions> _options({
  ConsentStateEnum mandatory = ConsentStateEnum.accepted,
  ConsentStateEnum optional = ConsentStateEnum.accepted,
}) => ConsentOptionsModel<FakeOptions>(
  options: {FakeOptions.mandatory: mandatory, FakeOptions.optional: optional},
);

void main() {
  group("ConsentOptionsModel.fromKeys", () {
    test("answers the same thing on every option of the consent", () {
      final options = ConsentOptionsModel<FakeOptions>.fromKeys(
        FakeOptions.values,
        ConsentStateEnum.notAccepted,
      );

      expect(options.optionMap, {
        FakeOptions.mandatory: ConsentStateEnum.notAccepted,
        FakeOptions.optional: ConsentStateEnum.notAccepted,
      });
    });
  });

  group("ConsentOptionsModel.copy", () {
    test("holds what the options it copies hold", () {
      final copy = ConsentOptionsModel<FakeOptions>.copy(_options());

      expect(copy, _options());
    });

    test("is a copy the changes of which do not reach the options it was built from", () {
      final options = _options();

      ConsentOptionsModel<FakeOptions>.copy(
        options,
      ).setOptionState(FakeOptions.mandatory, ConsentStateEnum.notAccepted);

      expect(options.getOptionState(FakeOptions.mandatory), ConsentStateEnum.accepted);
    });
  });

  group("ConsentOptionsModel.getOptionState", () {
    test("answers what the user answered on an option", () {
      final options = _options(optional: ConsentStateEnum.notAccepted);

      expect(options.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });

    test("knows nothing of an option the consent does not carry", () {
      const options = ConsentOptionsModel<FakeOptions>(options: {});

      expect(options.getOptionState(FakeOptions.mandatory), ConsentStateEnum.unknown);
    });
  });

  group("ConsentOptionsModel.setOptionState", () {
    test("keeps what the user answered on an option", () {
      final options = _options();

      options.setOptionState(FakeOptions.optional, ConsentStateEnum.notAccepted);

      expect(options.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });
  });

  group("ConsentOptionsModel.merge", () {
    test("takes the answers of the options it is given", () {
      final options = _options();

      final merged = options.merge(options: _options(optional: ConsentStateEnum.notAccepted));

      expect(merged.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });

    test("keeps its own answer on an option the other says nothing about", () {
      final options = _options(optional: ConsentStateEnum.notAccepted);

      final merged = options.merge(
        options: const ConsentOptionsModel<FakeOptions>(
          options: {FakeOptions.mandatory: ConsentStateEnum.accepted},
        ),
      );

      expect(merged.getOptionState(FakeOptions.optional), ConsentStateEnum.notAccepted);
    });

    test("drops an option it does not carry itself", () {
      const options = ConsentOptionsModel<FakeOptions>(
        options: {FakeOptions.mandatory: ConsentStateEnum.notAccepted},
      );

      final merged = options.merge(options: _options());

      expect(merged.optionMap.keys, [FakeOptions.mandatory]);
    });
  });

  group("ConsentOptionsModel.isAccepted", () {
    test("says that a consent every option of which was accepted is accepted", () {
      expect(_options().isAccepted, isTrue);
    });

    test("says that a consent whose optional option was refused is accepted", () {
      expect(_options(optional: ConsentStateEnum.notAccepted).isAccepted, isTrue);
    });

    test("says that a consent whose mandatory option was refused is not accepted", () {
      expect(_options(mandatory: ConsentStateEnum.notAccepted).isAccepted, isFalse);
    });

    test("says that a consent nothing is known of is accepted", () {
      final options = ConsentOptionsModel<FakeOptions>.fromKeys(
        FakeOptions.values,
        ConsentStateEnum.unknown,
      );

      expect(options.isAccepted, isTrue);
    });
  });

  group("ConsentOptionsModel", () {
    test("is the same options as another one which holds the same answers", () {
      expect(_options(), _options());
      expect(_options().hashCode, _options().hashCode);
    });

    test("is another options as soon as one answer differs", () {
      expect(_options(), isNot(_options(optional: ConsentStateEnum.notAccepted)));
    });
  });
}
