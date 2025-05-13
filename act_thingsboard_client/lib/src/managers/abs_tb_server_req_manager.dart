import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:act_thingsboard_client/src/managers/tb_no_auth_server_req_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

abstract class AbsTbServerReqBuilder<Tb extends AbsTbServerReqManager>
    extends AbsManagerBuilder<Tb> {
  AbsTbServerReqBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager, TbNoAuthServerReqManager];
}

abstract class AbsTbServerReqManager extends AbsWithLifeCycle {
  final String _logCategory;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  late final TbNoAuthServerReqManager _noAuthManager;

  /// The devices service linked to the manager
  late final TbDevicesService devicesService;

  @protected
  TbNoAuthServerReqManager get noAuthManager => _noAuthManager;

  ThingsboardClient get tbClient => _noAuthManager.tbClient;

  AbsTbServerReqManager({
    required String logCategory,
  }) : _logCategory = logCategory;

  /// Init the service
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: tb_constants.getSubLog(subCategory: _logCategory),
    );

    _noAuthManager = globalGetIt().get<TbNoAuthServerReqManager>();
    devicesService = TbDevicesService(requestManager: this, logsHelper: _logsHelper);

    await devicesService.initLifeCycle();
  }

  Future<TbRequestResponse<T>> request<T>(tb_constants.TbRequestToCall<T> requestToCall);

  /// Manager dispose method
  @override
  Future<void> disposeLifeCycle() async {
    await devicesService.disposeLifeCycle();

    await super.disposeLifeCycle();
  }
}
