library;

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

const logRootCategory = "tb";

/// This delegate is used to encapsulate the Thingsboard methods in order to use them in safe mode
typedef TbRequestToCall<T> = Future<T> Function(ThingsboardClient tbClient);

String getSubLog({required String subCategory}) =>
    "$logRootCategory${LogsHelper.logsCategorySeparator}$subCategory";
