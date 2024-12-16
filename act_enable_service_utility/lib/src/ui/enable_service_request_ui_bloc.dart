// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_enable_service_utility/src/mixin_enable_service.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';

/// This bloc is used to build a request ui bloc for an enabled service process
class EnableServiceRequestUiBloc<T extends MEnableService>
    extends RequestUserUiBloc {
  /// Class constructor
  ///
  /// [manager] is the service linked to this view request.
  EnableServiceRequestUiBloc({
    required super.actionIfAccepted,
    required super.requestUser,
    required T manager,
  }) : super(
          isOkCallback: () => manager.isEnabled,
          isOkStream: manager.enabledStream,
        );
}
