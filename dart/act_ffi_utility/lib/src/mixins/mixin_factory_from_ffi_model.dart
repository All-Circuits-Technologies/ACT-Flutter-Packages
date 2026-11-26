// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Mixin for converting FFI models to Dart models.
mixin MixinFactoryFromFfiModel<M extends Equatable, FfiModel> {
  /// {@template act_ffi_utility.MixinFactoryFromFfiModel.fromFfi}
  /// Convert an FFI model to a Dart model.
  /// {@endtemplate}
  M? fromFfi(FfiModel? ffiModel);
}
