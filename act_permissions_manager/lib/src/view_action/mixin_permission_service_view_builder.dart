// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/view_action/permission_view_action.dart';
import 'package:act_permissions_manager/src/view_action/permission_view_context.dart';

/// Add specific methods to [AbstractViewBuilder] when using permissions service utility
mixin MixinPermissionServiceViewBuilder on AbstractViewBuilder {
  /// This allows to register a page to display when a permission is asked to user
  void onPermissionPage({
    required MixinRoute route,
    required PermissionElement permElement,
    required PermissionViewAction permAction,
  }) =>
      onContextualPage(
        context: PermissionViewContext(
          element: permElement,
          action: permAction,
        ),
        route: route,
      );

  /// This allows to register a dialog to display when a permission is asked to user
  void onPermissionDialog({
    required PermissionElement permElement,
    required PermissionViewAction permAction,
    required DisplayDialog<PermissionViewContext> displayDialog,
  }) =>
      onContextualDialog(
        context: PermissionViewContext(
          element: permElement,
          action: permAction,
        ),
        displayDialog: displayDialog,
      );
}
