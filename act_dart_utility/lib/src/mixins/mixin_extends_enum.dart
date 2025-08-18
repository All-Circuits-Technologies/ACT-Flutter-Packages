// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin helps the management of multiple enums and merge them into one list
///
/// You can add this mixin on a "derived" enum
mixin MixinExtendsEnum on Enum {
  /// {@template MixinExtendsEnum.idxToInsertInSharedEnum}
  /// This is the index to use to insert the column key in the shared table.
  ///
  /// The elements are inserted in the order of the enums. Therefore, this index has to be the
  /// index of the enum in the shared table after the previous one is added.
  /// {@endtemplate}
  int get idxToInsertInSharedEnum;

  /// {@template MixinExtendsEnum.getAllColumns}
  /// Get all the columns of the [sharedEnums] and adds the [specificEnums] in it.
  ///
  /// Be careful: if B is something else than a strict [Enum], B must be a Mixin and has to be
  /// used with the two enums list: [sharedEnums] and [specificEnums]
  ///
  /// Unfortunately, there is no way to verify that C also inherit from B; therefore, you have to
  /// verify it yourself before calling this method.
  /// {@endtemplate}
  static List<B> getAllColumns<B extends Enum, C extends MixinExtendsEnum>({
    required List<B> sharedEnums,
    required List<C> specificEnums,
  }) {
    if (specificEnums is! List<B>) {
      // This returns an empty list if the C generic doesn't derive from B either
      return const [];
    }

    final enums = List<B>.from(sharedEnums);
    for (final tmpEnum in specificEnums) {
      enums.insert(tmpEnum.idxToInsertInSharedEnum, tmpEnum as B);
    }

    return enums;
  }
}
