// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';

/// Builder of the [AbstractPeriphManager] manager
abstract class AbstractPeriphBuilder<M extends AbstractPeriphManager> extends AbsManagerBuilder<M>
    with MPermissionsServiceBuilder {
  /// Class constructor
  AbstractPeriphBuilder(super.factory);
}

/// This is the abstract manager for the managers linked to peripherals component such as WiFi, BLE,
/// background, location, etc.
abstract class AbstractPeriphManager extends AbsWithLifeCycle
    with MPermissionsService, MEnableService {
  /// Is peripheral fully enabled
  bool isFullyEnabled() => isEnabled && hasPermissions;

  /// This method checks and asks for permissions (if needed) and for service activation
  ///
  /// Better to use this method instead of calling [checkAndAskPermissions] and
  /// [checkAndAskForEnabling] separately; because the method waits for the permissions updates
  /// before verifying for the service state
  ///
  /// if [askActionsToUser] is equal to true, the method asks their permissions to the user if
  /// needed
  /// if [askActionsToUser] is equal to false, the method only checks for the current statuses
  ///
  /// If [displayContextualIfNeeded] is equals to true, if the permissions aren't granted and if the
  /// service is not enabled, the method will ask to display a HMI to inform the user of the
  /// necessity to grant the permissions and enable the service.
  /// If false, no HMI is displayed and we redirect the user to the system permissions page or
  /// activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted or the service is
  /// disabled.
  Future<bool> checkAndAskForPermissionsAndServices({
    bool askActionsToUser = true,
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (!askActionsToUser) {
      return hasPermissions && isEnabled;
    }

    if (!await checkAndAskPermissions(
      displayContextualIfNeeded: displayContextualIfNeeded,
      isAcceptanceCompulsory: isAcceptanceCompulsory,
    )) {
      return false;
    }

    return checkAndAskForEnabling(
      isAcceptanceCompulsory: isAcceptanceCompulsory,
    );
  }
}
