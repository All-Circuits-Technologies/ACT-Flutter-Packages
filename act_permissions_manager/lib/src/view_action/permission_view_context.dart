// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/view_action/permission_view_action.dart';

/// Defines the view context for permissions
class PermissionViewContext extends AbstractViewContext {
  /// This the global prefix key for the permissions
  static const _globalPermKey = "permission";

  /// The permission element
  final PermissionElement element;

  /// The action linked to the permission
  final PermissionViewAction action;

  /// True if the user has the obligation to grant the permissions to leave the page
  final bool isAcceptanceCompulsory;

  /// Class constructor
  PermissionViewContext({
    required this.element,
    required this.action,
    this.isAcceptanceCompulsory = false,
  }) : super(
          uniqueKey: PermissionViewContext._createUniqueKey(
            element: element,
            action: action,
          ),
        );

  /// Class constructor for managing the ask permission action
  factory PermissionViewContext.askPermission({
    required PermissionElement element,
    bool isAcceptanceCompulsory = false,
  }) =>
      _createPermission(
        action: PermissionViewAction.askPermission,
        element: element,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );

  /// Class constructor for managing the inform permanently denied
  factory PermissionViewContext.informPermanentlyDenied({
    required PermissionElement element,
  }) =>
      _createPermission(
        action: PermissionViewAction.informPermanentlyDenied,
        element: element,
        isAcceptanceCompulsory: false,
      );

  /// Create the permission view context
  static PermissionViewContext _createPermission({
    required PermissionViewAction action,
    required PermissionElement element,
    required bool isAcceptanceCompulsory,
  }) =>
      PermissionViewContext(
        element: element,
        action: action,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );

  /// Create the unique key linked to the permission view context
  static String _createUniqueKey({
    required PermissionElement element,
    required PermissionViewAction action,
  }) =>
      "$_globalPermKey:$element:$action";
}
