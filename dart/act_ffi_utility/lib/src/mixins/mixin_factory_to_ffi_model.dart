// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Mixin for converting a Dart model to an FFI model.
mixin MixinFactoryToFfiModel<M extends Equatable, FfiModel> {
  /// {@template act_ffi_utility.MixinFactoryToFfiModel.toFfi}
  /// Convert a Dart model to an FFI model.
  /// {@endtemplate}
  FfiModel toFfi(M model);
}
