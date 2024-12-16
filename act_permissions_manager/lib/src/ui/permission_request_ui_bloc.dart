// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_permissions_manager/src/services_helper/mixin_permissions_service.dart';

/// Bloc for the permission request ui
class PermissionRequestUiBloc<T extends MPermissionsService> extends RequestUserUiBloc {
  /// Class constructor
  ///
  /// [manager] is the service linked to this view request.
  PermissionRequestUiBloc({
    required super.actionIfAccepted,
    required super.requestUser,
    required T manager,
  }) : super(
          isOkCallback: () => manager.hasPermissions,
          isOkStream: manager.permissionsStream,
        );
}
