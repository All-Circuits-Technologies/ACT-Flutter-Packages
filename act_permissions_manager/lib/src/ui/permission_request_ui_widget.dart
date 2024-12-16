// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/src/services_helper/mixin_permissions_service.dart';
import 'package:act_permissions_manager/src/ui/permission_request_ui_bloc.dart';
import 'package:flutter/material.dart';

/// Display a page to ask for the user acknowledgement before redirect him to the system page for
/// granting the service permissions
class PermissionRequestUiWidget<T extends MPermissionsService> extends AbstractRequestUserUiWidget {
  /// Class constructor
  PermissionRequestUiWidget({
    super.key,
    required super.acceptanceButtonBuilder,
    required VoidCallback actionIfAccepted,
    required super.childrenBuilder,
    required RequestUserCallback askForPermission,
    super.refusalButtonBuilder,
    super.spaceBetweenChildrenAndButtons,
    super.spaceBetweenButtons,
    super.spaceAfterButtons,
    super.scaffoldBuilder,
  }) : super(
          blocBuilder: (context) => PermissionRequestUiBloc(
            actionIfAccepted: actionIfAccepted,
            manager: globalGetIt().get<T>(),
            requestUser: askForPermission,
          ),
        );
}
