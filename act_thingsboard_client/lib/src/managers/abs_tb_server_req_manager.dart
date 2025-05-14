// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:flutter/foundation.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the manager builder for the derived [AbsTbServerReqManager] manager
abstract class AbsTbServerReqBuilder<Tb extends AbsTbServerReqManager>
    extends AbsManagerBuilder<Tb> {
  /// Class constructor
  AbsTbServerReqBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, TbNoAuthServerReqManager];
}

/// This is the abstract manager to extend in order to manage the request to Thingsboard.
///
/// {@template act_thingsboard_client.AbsTbServerReqManager.details}
/// All the requests done through this manager are authenticated and a token is set in the request
/// header.
///
/// To send no authenticated requests better to use: [TbNoAuthServerReqManager]
/// {@endtemplate}
abstract class AbsTbServerReqManager extends AbsWithLifeCycle {
  /// This is the log category of the manager
  final String _logCategory;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// This is the manager to request the server without authentication
  late final TbNoAuthServerReqManager _noAuthManager;

  /// The devices service linked to the manager
  late final TbDevicesService devicesService;

  /// This allows to access the no auth request manager
  @protected
  TbNoAuthServerReqManager get noAuthManager => _noAuthManager;

  /// This is the created thingsboard client
  ThingsboardClient get tbClient => _noAuthManager.tbClient;

  /// Class constructor
  AbsTbServerReqManager({
    required String logCategory,
  }) : _logCategory = logCategory;

  /// Init the service
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: tb_constants.getTbLogCategory(subCategory: _logCategory),
    );

    _noAuthManager = globalGetIt().get<TbNoAuthServerReqManager>();
    devicesService = TbDevicesService(requestManager: this, logsHelper: _logsHelper);

    await devicesService.initLifeCycle();
  }

  /// {@template act_thingsboard_client.AbsTbServerReqManager.request}
  /// Encapsulate the request to the server.
  ///
  /// The method must manage the adding of tokens info in the given ThingsboardClient
  /// {@endtemplate}
  Future<TbRequestResponse<T>> request<T>(tb_constants.TbRequestToCall<T> requestToCall);

  /// Manager dispose method
  @override
  Future<void> disposeLifeCycle() async {
    await devicesService.disposeLifeCycle();

    await super.disposeLifeCycle();
  }
}
