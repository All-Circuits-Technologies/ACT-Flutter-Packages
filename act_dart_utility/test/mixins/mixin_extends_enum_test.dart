// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contract the shared columns and the specific ones both answer.
mixin _Column on Enum {}

/// The columns every application shares.
enum _SharedColumn with _Column { name, date }

/// The columns an application adds to the shared ones.
enum _SpecificColumn with _Column, MixinExtendsEnum {
  batch(1),
  operator(3);

  @override
  final int idxToInsertInSharedEnum;

  const _SpecificColumn(this.idxToInsertInSharedEnum);
}

/// An enum which extends nothing the shared columns know about.
enum _ForeignEnum with MixinExtendsEnum {
  alone(0);

  @override
  final int idxToInsertInSharedEnum;

  const _ForeignEnum(this.idxToInsertInSharedEnum);
}

void main() {
  group("MixinExtendsEnum.getAllColumns", () {
    test("inserts every specific value at the index it asks for", () {
      expect(
        MixinExtendsEnum.getAllColumns<_Column, _SpecificColumn>(
          sharedEnums: _SharedColumn.values,
          specificEnums: _SpecificColumn.values,
        ),
        [_SharedColumn.name, _SpecificColumn.batch, _SharedColumn.date, _SpecificColumn.operator],
      );
    });

    test("returns the shared values alone when there is no specific one", () {
      expect(
        MixinExtendsEnum.getAllColumns<_Column, _SpecificColumn>(
          sharedEnums: _SharedColumn.values,
          specificEnums: const [],
        ),
        _SharedColumn.values,
      );
    });

    test("appends a specific value whose index is the length of the list it joins", () {
      expect(
        MixinExtendsEnum.getAllColumns<_Column, _SpecificColumn>(
          sharedEnums: const [_SharedColumn.name],
          specificEnums: const [_SpecificColumn.batch],
        ),
        [_SharedColumn.name, _SpecificColumn.batch],
      );
    });

    test("leaves the shared values untouched", () {
      MixinExtendsEnum.getAllColumns<_Column, _SpecificColumn>(
        sharedEnums: _SharedColumn.values,
        specificEnums: _SpecificColumn.values,
      );

      expect(_SharedColumn.values, [_SharedColumn.name, _SharedColumn.date]);
    });

    test("returns nothing when the specific values do not answer the shared contract", () {
      expect(
        MixinExtendsEnum.getAllColumns<_Column, _ForeignEnum>(
          sharedEnums: _SharedColumn.values,
          specificEnums: _ForeignEnum.values,
        ),
        isEmpty,
      );
    });
  });
}
