// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_thingsboard_conf.dart';
import 'package:act_thingsboard_client/src/services/devices/tb_devices_service.dart';
import 'package:act_thingsboard_client/src/services/tb_request_service.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This delegate is used to encapsulate the Thingsboard methods in order to use them in safe mode
typedef TbRequestToCall<T> = Future<T> Function(ThingsboardClient tbClient);

/// Builder linked to the [ThingsboardManager]
class ThingsboardBuilder<E extends MixinThingsboardConf>
    extends AbsManagerBuilder<ThingsboardManager<E>> {
  /// Builder constructor
  ThingsboardBuilder() : super(ThingsboardManager<E>.new);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, E];
}

/// The Thingsboard manager which managed the authentication to the server but also the call of
/// requests in safe mode
class ThingsboardManager<E extends MixinThingsboardConf> extends AbsWithLifeCycle {
  /// Thingsboard logs category
  static const _tbLogsCategory = "TB";

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// The devices service linked to the manager
  late final TbDevicesService devicesService;

  /// The request service linked to the manager
  late final TbRequestService<E> _requestService;

  /// Class constructor
  ThingsboardManager() : super();

  /// Init manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _tbLogsCategory,
    );

    _requestService = TbRequestService<E>(logsHelper: _logsHelper);
    devicesService = TbDevicesService(requestService: _requestService, logsHelper: _logsHelper);

    await devicesService.initLifeCycle();
  }

  /// Useful to sign in the current user to its account
  Future<bool> signIn({
    required String username,
    required String password,
    int retryRequestIfErrorNb = 0,
    Duration? retryTimeout,
  }) async =>
      _requestService.signIn(
        username: username,
        password: password,
        retryRequestIfErrorNb: retryRequestIfErrorNb,
        retryTimeout: retryTimeout,
      );

  /// Get the username and password information from memory and sign in the user with it
  Future<bool> signInFromMemory() async => _requestService.signInFromMemory();

  /// Logout the user and erase the credentials from memory
  Future<void> logout() async => _requestService.logout();

  /// Manager dispose method
  @override
  Future<void> disposeLifeCycle() async {
    await devicesService.disposeLifeCycle();

    // Request service has to be the last one disposed
    await _requestService.disposeLifeCycle();

    await super.disposeLifeCycle();
  }
}
