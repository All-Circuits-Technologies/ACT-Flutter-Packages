// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/src/enable_service_view_context.dart';
import 'package:act_enable_service_utility/src/mixin_enable_service.dart';

/// This bloc is used to build a request ui bloc for an enabled service process
class EnableServiceRequestUiBloc<T extends MEnableService>
    extends RequestContextualActionBloc<EnableServiceViewContext> {
  /// Class constructor
  ///
  /// [manager] is the service linked to this view request.
  EnableServiceRequestUiBloc({
    required super.config,
    required T manager,
  }) : super(
          isOkCallback: () => manager.isEnabled,
          isOkStream: manager.enabledStream,
        );
}
