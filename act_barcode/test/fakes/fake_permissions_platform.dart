// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// Answer the permissions of the device from the test.
///
/// This is what the plugin of the permissions reads and writes; the test decides the status of each
/// permission and reads back which ones were requested.
class FakePermissionsPlatform extends PermissionHandlerPlatform {
  /// Hold the status of each permission, the ones which are absent being denied.
  final Map<Permission, PermissionStatus> statuses;

  /// Hold the status a permission takes once it has been requested, per permission.
  ///
  /// A permission which is absent is granted once it has been requested.
  final Map<Permission, PermissionStatus> answersToRequest;

  /// Hold the permissions which were requested, in the order they were.
  final List<Permission> requested;

  /// Hold what the settings of the application become when they are opened.
  final Map<Permission, PermissionStatus> settingsAnswer;

  /// Make reading a permission wait for it to be completed, when it is set.
  Completer<void>? gate;

  /// Count the times the settings of the application were opened.
  int settingsCount;

  /// Create the platform, where no permission is granted and nothing was requested.
  FakePermissionsPlatform()
    : statuses = {},
      answersToRequest = {},
      requested = [],
      settingsAnswer = {},
      settingsCount = 0;

  /// Check the status of the [permission], once the [gate] is open.
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    await gate?.future;

    return statuses[permission] ?? PermissionStatus.denied;
  }

  /// Request the [permissions], which take the status the test planned for them.
  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    final answers = <Permission, PermissionStatus>{};

    for (final permission in permissions) {
      requested.add(permission);
      final answer = answersToRequest[permission] ?? PermissionStatus.granted;
      statuses[permission] = answer;
      answers[permission] = answer;
    }

    return answers;
  }

  /// Say that no permission needs a rationale.
  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;

  /// Open the settings of the application, which take the [settingsAnswer].
  @override
  Future<bool> openAppSettings() async {
    settingsCount++;
    statuses.addAll(settingsAnswer);

    return true;
  }

  /// Install a new platform as the one the plugin of the permissions reads, and give it back.
  static FakePermissionsPlatform install() {
    final platform = FakePermissionsPlatform();
    PermissionHandlerPlatform.instance = platform;

    return platform;
  }
}
