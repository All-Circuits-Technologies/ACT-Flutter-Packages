// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_manager/src/handlers/abstract_jwt_handler.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// The manager builder linked to the [JwtManager]
class JwtBuilder extends ManagerBuilder<JwtManager> {
  /// Class constructor
  JwtBuilder() : super(() => JwtManager());

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This is the JWT manager
///
/// Each "kind" of JWT is managed by a specific handler
class JwtManager extends AbstractManager {
  /// This os the JWT logs category to use
  static const _jwtLogsCategory = "jwt";

  /// The JWT handlers
  final Map<String, AbstractJwtHandler> _jwtHandlers;

  /// The [LogsHelper] linked to the manager
  late final LogsHelper logsHelper;

  /// Class constructor
  JwtManager() : _jwtHandlers = {};

  /// Init method of the manager
  @override
  Future<void> initManager() async {
    logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _jwtLogsCategory,
    );
  }

  /// Add and init a JWT handler
  Future<bool> addAndInitJwtHandler(AbstractJwtHandler handler) async {
    if (!(await handler.initHandler())) {
      logsHelper.w("A problem occurred when tried to initialize the JWT handler given: "
          "${handler.name}");
      return false;
    }

    if (handler.canSignAndVerify && (!(await handler.testSignAndVerify()))) {
      logsHelper.w("A problem occurred when tried to test the JWT handler given: ${handler.name}");
      return false;
    }

    _jwtHandlers[handler.name] = handler;

    return true;
  }
}
