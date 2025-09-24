// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/value_keeper.dart';

/// {@macro act_dart_utility.ValueKeeper}
///
/// This class also save the information if the value has been explicitly initialized, or not
class ValueKeeperWithInitInfo<T> extends ValueKeeper<T> {
  /// This is true if the value has been explicitly initialized at least once
  bool _hasBeenInitialized;

  /// Returns true if the value has been explicitly initialized at least once
  bool get hasBeenInitialized => _hasBeenInitialized;

  /// {@macro act_dart_utility.ValueKeeper.value.setter}
  @override
  set value(T? newValue) {
    if (!_hasBeenInitialized) {
      _hasBeenInitialized = true;
    }

    super.value = newValue;
  }

  /// Create a ValueKeeperWithInitInfo with no initial value
  ///
  /// Therefore, [hasBeenInitialized] will return false if the [value] setter is not used
  ValueKeeperWithInitInfo.noInit() : _hasBeenInitialized = false;

  /// Create a ValueKeeperWithInitInfo with an initial value
  ///
  /// Therefore, [hasBeenInitialized] will return true even if the [value] setter is not used
  ValueKeeperWithInitInfo.withInit({required super.value}) : _hasBeenInitialized = true;
}
