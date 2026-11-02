// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/src/mixins/mixin_ui_life_cycle.dart';
import 'package:act_life_cycle/src/services/abs_with_life_cycle.dart';

/// Abstract class for all the application managers and services which depends on UI
///
/// This is used to simplify the extension of the [AbsWithLifeCycle] and the mixin
/// [MixinUiLifeCycle] by merging them together in one class.
abstract class AbsWithLifeCycleAndUi extends AbsWithLifeCycle with MixinUiLifeCycle;
