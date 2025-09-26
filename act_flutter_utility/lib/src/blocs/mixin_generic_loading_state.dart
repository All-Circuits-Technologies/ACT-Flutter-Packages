// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// A mixin for [BlocStateForMixin] that need to manage generic loading states.
///
/// This is useful when you want to display generic widgets one at least one element is loading or
/// an error occurred.
mixin MixinGenericLoadingState<S extends BlocStateForMixin<S>> on BlocStateForMixin<S> {
  /// {@template act_flutter_utility.MixinGenericLoadingState.loading}
  /// True when at least one element of the view is loading.
  /// {@endtemplate}
  bool get loading;

  /// {@template act_flutter_utility.MixinGenericLoadingState.anErrorOccurred}
  /// True when an error occurred in one loading.
  /// {@endtemplate}
  bool get anErrorOccurred;
}
