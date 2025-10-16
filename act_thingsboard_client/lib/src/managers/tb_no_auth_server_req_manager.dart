// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/act_tb_storage.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the builder of the [TbNoAuthServerReqManager] class
///
/// The [TbNoAuthServerReqManager] doesn't depend on [AbsAuthManager], it only passes the
/// `storageService` to the created ThingsboardClient.
class TbNoAuthServerReqBuilder<C extends MixinThingsboardConf, A extends AbsAuthManager>
    extends AbsManagerBuilder<TbNoAuthServerReqManager> {
  /// Class constructor
  TbNoAuthServerReqBuilder()
      : super(() => TbNoAuthServerReqManager(
              storageServiceGetter: () => globalGetIt().get<A>().storageService,
              confGetter: globalGetIt().get<C>,
            ));

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [C, LoggerManager];
}

/// This manager is helpful to requests the Thingsboard server without authentication.
///
/// The manager creates the [ThingsboardClient] to use.
///
/// It's helpful to call Thingsboard requests which doesn't depend on authentication.
class TbNoAuthServerReqManager extends AbsWithLifeCycle {
  /// This is the log category used with the manager
  static final _noAuthTbLogsCategory = tb_constants.getTbLogCategory(subCategory: "noAuth");

  /// The [ThingsboardClient] used to request Thingsboard
  late final ThingsboardClient _tbClient;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// This is the thingsboard storage used with [_tbClient]
  final ActTbStorage _tbStorage;

  /// The method is used to get the wanted Thingsboard conf
  final MixinThingsboardConf Function() _confGetter;

  /// Getter to get the linked [ThingsboardClient]
  ThingsboardClient get tbClient => _tbClient;

  /// Class constructor
  TbNoAuthServerReqManager({
    required MixinAuthStorageService? Function()? storageServiceGetter,
    required MixinThingsboardConf Function() confGetter,
  })  : _tbStorage = ActTbStorage(storageServiceGetter: storageServiceGetter),
        _confGetter = confGetter;

  /// Init the service
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _noAuthTbLogsCategory,
    );

    final confManager = _confGetter();
    final hostname = confManager.tbHostname.load();
    final port = confManager.tbPort.load();

    if (hostname == null) {
      _logsHelper.e("The Thingsboard hostname hasn't been given");
      throw Exception("The Thingsboard hostname hasn't been given");
    }

    final uri = Uri(port: port, host: hostname, scheme: UriUtility.httpsScheme);

    _tbClient = ThingsboardClient(uri.toString(), storage: _tbStorage);

    _logsHelper.i("Initialize connection to thingsboard service at url: $uri");
  }

  /// The method allows to call Thingsboard request and catches the error throwing from it for
  /// returning [RequestStatus] information
  ///
  /// The method doesn't manage the reconnection and/or getting of user tokens
  Future<TbRequestResponse<T>> request<T>(tb_constants.TbRequestToCall<T> requestToCall) async {
    var status = RequestStatus.success;
    T? result;

    try {
      result = await requestToCall(_tbClient);
    } on ThingsboardError catch (error) {
      status = RequestStatus.globalError;

      if (error.errorCode == ThingsBoardErrorCode.general) {
        _logsHelper.w("A generic error happens on Thingsboard when tried to request it: $error");
        _logsHelper.w("Source of the error: ${error.error}");
      } else if (error.errorCode == ThingsBoardErrorCode.jwtTokenExpired ||
          error.errorCode == ThingsBoardErrorCode.authentication) {
        status = RequestStatus.loginError;
      }
    } catch (error) {
      status = RequestStatus.globalError;
      _logsHelper.d("An error occurred when requesting Thingsboard: $error");
    }

    return TbRequestResponse<T>(status: status, requestResponse: result);
  }
}
