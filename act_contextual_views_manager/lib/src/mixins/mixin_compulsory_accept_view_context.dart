// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';

/// This mixin adds an optional parameter to the [AbstractViewContext], which is the test if
/// acceptance of the view is compulsory
mixin MixinCompulsoryAcceptViewContext on AbstractViewContext {
  /// True if the user has the obligation to do something to leave the page
  bool get isAcceptanceCompulsory;
}
