import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client/src/act_tb_storage.dart';
import 'package:act_thingsboard_client/src/constants/tb_constants.dart' as tb_constants;
import 'package:thingsboard_client/thingsboard_client.dart';

class TbNoAuthServerReqBuilder<C extends MixinThingsboardConf, A extends AbsAuthManager>
    extends AbsManagerBuilder<TbNoAuthServerReqManager> {
  TbNoAuthServerReqBuilder()
      : super(() => TbNoAuthServerReqManager(
              storageServiceGetter: () => globalGetIt().get<A>().storageService,
              confGetter: globalGetIt().get<C>,
            ));

  @override
  Iterable<Type> dependsOn() => [C, LoggerManager];
}

class TbNoAuthServerReqManager extends AbsWithLifeCycle {
  static final _noAuthTbLogsCategory = tb_constants.getSubLog(subCategory: "noAuth");

  /// The [ThingsboardClient] used to request Thingsboard
  late final ThingsboardClient _tbClient;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  final ActTbStorage _tbStorage;

  final MixinThingsboardConf Function() _confGetter;

  /// Getter to get the linked [ThingsboardClient]
  ThingsboardClient get tbClient => _tbClient;

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

    final uri = Uri(port: port, host: hostname, scheme: ServerReqConstants.httpsScheme);

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
