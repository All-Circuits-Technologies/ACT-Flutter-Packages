// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/mixins/mixin_ui_global_manager.dart';
import 'package:act_global_manager/src/services/abs_global_manager.dart';

/// Abstract class for all the global managers and services which depends on UI
///
/// This is used to simplify the extension of the [AbsGlobalManager] and the mixin
/// [MixinUiGlobalManager] by merging them together in one class.
abstract class AbsUiGlobalManager extends AbsGlobalManager with MixinUiGlobalManager {
  /// {@macro act_global_manager.AbsGlobalManager.create}
  AbsUiGlobalManager.create({super.defaultMinLevel}) : super.create();
}
