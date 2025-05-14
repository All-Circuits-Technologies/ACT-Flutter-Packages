// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This is the log root category used in all the package
const logRootCategory = "tb";

/// This delegate is used to encapsulate the Thingsboard methods in order to use them in safe mode
typedef TbRequestToCall<T> = Future<T> Function(ThingsboardClient tbClient);

/// Get the right log category for the elements in the thingsboard package
String getTbLogCategory({required String subCategory}) =>
    "$logRootCategory${LogsHelper.logsCategorySeparator}$subCategory";
