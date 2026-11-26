// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/blocs/bloc_event_for_mixin.dart';

/// This is the event used to trigger the async initialization of the bloc.
class AsyncInitEvent extends BlocEventForMixin {
  /// Class constructor
  const AsyncInitEvent();
}
