// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_permissions_manager/src/services_helper/mixin_permissions_service.dart';
import 'package:act_permissions_manager/src/view_action/permission_view_context.dart';

/// Bloc for the permission request ui
class PermissionRequestUiBloc<T extends MPermissionsService>
    extends RequestContextualActionBloc<PermissionViewContext> {
  /// Class constructor
  ///
  /// [manager] is the service linked to this view request.
  PermissionRequestUiBloc({
    required super.config,
    required T manager,
  }) : super(
          isOkCallback: () => manager.hasPermissions,
          isOkStream: manager.permissionsStream,
        );
}
