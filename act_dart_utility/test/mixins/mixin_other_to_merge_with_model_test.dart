// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

/// The values which may override the ones of a configuration.
class _Override extends Equatable {
  final String? host;

  const _Override({this.host});

  @override
  List<Object?> get props => [host];
}

/// A configuration which can be merged with an override.
class _Config extends Equatable with MixinOtherToMergeWithModel<_Config, _Override> {
  final String host;
  final int port;

  const _Config({required this.host, required this.port});

  @override
  _Config mergeWith(_Override mergeWith) => _Config(host: mergeWith.host ?? host, port: port);

  @override
  List<Object?> get props => [host, port];
}

void main() {
  group("MixinOtherToMergeWithModel.mergeWith", () {
    test("returns a new model built from the two of them", () {
      const config = _Config(host: "example.com", port: 80);

      expect(
        config.mergeWith(const _Override(host: "other.com")),
        const _Config(host: "other.com", port: 80),
      );
    });

    test("leaves the model untouched", () {
      const config = _Config(host: "example.com", port: 80);

      config.mergeWith(const _Override(host: "other.com"));

      expect(config.host, "example.com");
    });

    test("returns an equal model when there is nothing to override", () {
      const config = _Config(host: "example.com", port: 80);

      expect(config.mergeWith(const _Override()), config);
    });
  });
}
