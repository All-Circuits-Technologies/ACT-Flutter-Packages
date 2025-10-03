// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This abstract class is the base class for all storage items.
abstract class AbsStorageItem<T> extends Equatable {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// Class constructor
  const AbsStorageItem({required this.key});

  /// {@template act_local_storage_manager.AbsStorageItem.load}
  /// Load value from storage.
  ///
  /// Returns null if value is not found or fails to be parsed.
  /// {@endtemplate}
  Future<T?> load();

  /// {@template act_local_storage_manager.AbsStorageItem.load}
  /// Store value to storage.
  ///
  /// Returns false if a problem occurred.
  ///
  /// If [value] is null, we call [delete]
  /// {@endtemplate}
  Future<bool> store(T? value);

  /// {@template act_local_storage_manager.AbsStorageItem.delete}
  /// Remove value from storage.
  /// {@endtemplate}
  Future<void> delete();

  /// {@template act_local_storage_manager.AbsStorageItem.props}
  /// The storage item properties
  /// {@endtemplate}
  @override
  List<Object?> get props => [key];
}
