// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_enable_service_utility/src/enable_service_element.dart';
import 'package:act_enable_service_utility/src/enable_service_view_context.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/widgets.dart';

/// This mixin contains the management of service activation for Managers
mixin MEnableService on AbsWithLifeCycle {
  /// This is the timeout to wait for the service status after having open the phone settings
  static const defaultWaitForStatusAfterOpenSetting = Duration(seconds: 5);

  /// The controller for the activation controller
  final _enabledCtrl = StreamController<bool>.broadcast();

  /// Activation enable status
  bool _isEnabled = false;

  /// Say if the service is enabled or not
  bool get isEnabled => _isEnabled;

  /// The stream controller for the service state
  Stream<bool> get enabledStream => _enabledCtrl.stream;

  /// To call in order to update the service state
  /// We use a method instead of a setter because we may want to override the method.
  @protected
  // The method is used like a setter; therefore the parameter can be positional
  // ignore: avoid_positional_boolean_parameters
  void setEnabled(bool isEnabled) {
    if (_isEnabled != isEnabled) {
      _isEnabled = isEnabled;
      _enabledCtrl.add(isEnabled);
    }
  }

  /// Check and ask for service activation, if [askToUser] is equals to true, the method calls
  /// [askForEnabling] method otherwise it tests the current service status.
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the service is not enabled, the method
  /// will ask to display a HMI to inform the user of the necessity to enable the service. If false,
  /// no HMI displayed is and we redirect the user to the system activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  Future<bool> checkAndAskForEnabling({
    bool askToUser = true,
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (!askToUser) {
      return _isEnabled;
    }

    return askForEnabling(
      isAcceptanceCompulsory: isAcceptanceCompulsory,
      displayContextualIfNeeded: displayContextualIfNeeded,
    );
  }

  /// This is called when we want to activate the service linked to the manager
  /// The manager has to override this method in order to do particular things linked to its process
  /// The method has to return true if the service is enabled at the process end
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the service is not enabled, the method
  /// will ask to display a HMI to inform the user of the necessity to enable the service. If false,
  /// no HMI displayed is and we redirect the user to the system activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  @protected
  Future<bool> askForEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  });

  /// This may be called to display a dialog before asking for an user action (in order to enable)
  /// the service
  ///
  /// To override the default context to call another one, use the [overrideContext] parameter
  ///
  /// If [displayContextualIfNeeded] is equals to true, the method will display a HMI to inform the
  /// user of the necessity to enable the service. If false, no HMI is displayed and we return with
  /// the [ViewDisplayStatus.ok] status.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  ///
  /// Add in [manageEnabling], all the service enable asking: the opening of system page and waiting for
  /// the result.
  @protected
  Future<ViewDisplayResult<C>> requestUser<C>({
    EnableServiceViewContext? overrideContext,
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
    DoActionDisplayCallback<C>? manageEnabling,
  }) async {
    if (!displayContextualIfNeeded) {
      if (manageEnabling == null) {
        return const ViewDisplayResult(status: ViewDisplayStatus.ok);
      }

      final (result, value) = await manageEnabling();

      return ViewDisplayResult(
        status: result ? ViewDisplayStatus.ok : ViewDisplayStatus.error,
        customResult: value,
      );
    }

    return globalGetIt().get<ContextualViewsManager>().display(
          context: overrideContext ??
              EnableServiceViewContext(
                element: getElement(),
                isAcceptanceCompulsory: isAcceptanceCompulsory,
              ),
          doAction: manageEnabling,
        );
  }

  /// Opens the application wanted setting [settingsType] and wait for the status to be updated
  ///
  /// This is useful when the service status may take time to be updated after the return to the
  /// application.
  ///
  /// This method waits the app to recognise that we return to the app and then the value has been
  /// updated.
  /// If the value hasn't been updated by the user we wait the [timeout]
  ///
  /// See the method [WaitUtility.waitForStatus] for the parameters details.
  @protected
  static Future<T> openAppSettingAndWaitForUpdate<T>({
    required FutureOr<bool> Function(T status) isExpectedStatus,
    required FutureOr<T> Function() valueGetter,
    required Stream<T> statusEmitter,
    required AppSettingsType settingsType,
    Duration timeout = defaultWaitForStatusAfterOpenSetting,
  }) async =>
      WaitUtility.waitForStatus<T>(
        isExpectedStatus: isExpectedStatus,
        valueGetter: valueGetter,
        statusEmitter: statusEmitter,
        doAction: () async {
          await globalGetIt().get<LifeCycleManager>().waitForegroundApp(
            leaveTheApp: () async {
              await AppSettings.openAppSettings(type: settingsType);
              return true;
            },
          );
          return true;
        },
        timeout: timeout,
      );

  /// Get the element linked to this service
  @protected
  EnableServiceElement getElement();

  @override
  Future<void> disposeLifeCycle() async {
    await _enabledCtrl.close();
    await super.disposeLifeCycle();
  }
}
