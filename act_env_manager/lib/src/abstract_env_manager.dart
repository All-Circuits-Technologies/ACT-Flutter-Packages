// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'environment.dart';

/// Builder for creating the EnvManager
abstract class AbstractEnvBuilder<T extends AbstractEnvManager> extends ManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractEnvBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// [EnvManager] handles environment variable management.
///
/// Each supported environment variable is accessible through a public member,
/// which provides a getter to read from environment variables.
///
/// To choose the environment in flutter run/build, use the parameter "--dart-define"
/// Example : flutter run --dart-define="ENV=PROD".
/// Possible values are : DEV, STAGING and PROD.
abstract class AbstractEnvManager extends AbstractManager {
  /// The logs category linked to the env manager
  static const _logsCategory = "env";

  /// Environment used
  late final Environment env;

  /// The logs helper linked to the ENV manager
  late final LogsHelper _logsHelper;

  /// Path to configuration folder
  final String configPath;

  /// Allows to override the LOGS level of logger manager
  final logLevelEnv = EnvVar<String>('LOGS_LEVEL');

  /// Allows to override the LOGS print in release of logger manager
  final logPrintInReleaseEnv = EnvVar<bool>('LOGS_PRINT_IN_RELEASE');

  /// Builds an instance of [EnvManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractEnvManager({
    this.configPath = Environment.defaultConfigPath,
  }) : super() {
    env = Environment.fromString(const String.fromEnvironment(Environment.envType));
    appLogger().i('Environment loaded : $env');
  }

  /// Init the manager
  @override
  Future<void> initManager() async {
    _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory);

    // First, we load the default env
    if (!(await _loadEnvFromAsset(relativeFilePath: Environment.defaultEnv.relFilePath))) {
      return;
    }

    // Second, we load the current env to overload what it has been already loaded
    if (!(await _loadEnvFromAsset(relativeFilePath: env.relFilePath))) {
      return;
    }

    // Third, we load the local default file (which isn't committed)
    // The file may not exist, it's not compulsory
    // The local default file overload what it has been already loaded
    if (!(await _loadEnvFromAsset(
      relativeFilePath: Environment.local.relFilePath,
      mayTheFileNotExist: true,
    ))) {
      return;
    }

    await _reInitLoggerIfNecessary();

    _logsHelper.i('Environment variables loaded : ${dotenv.env}');
  }

  /// This method allows to reinitialize the logger manager if environment variables have been
  /// given and if the values are different from the default one
  Future<void> _reInitLoggerIfNecessary() async {
    final logsLevel = logLevelEnv.load();
    final printLogsInRelease = logPrintInReleaseEnv.load();

    if (logsLevel == null && printLogsInRelease == null) {
      // Nothing to do
      return;
    }

    final loggerManager = globalGetIt().get<LoggerManager>();

    final printLogsTmp = printLogsInRelease ?? loggerManager.currentInitConfig.printLogInRelease;
    final logsLevelTmp =
        LoggerInitConfig.parseLevel(logsLevel) ?? loggerManager.currentInitConfig.logLevel;

    await loggerManager.reInitLogger(
      initConfig: LoggerInitConfig(
        logLevel: logsLevelTmp,
        printLogInRelease: printLogsTmp,
      ),
    );
  }

  /// Load environment variables from the config asset given
  ///
  /// If [mayTheFileNotExist] given is equal to true, it means that the asset config file may not
  /// exist (and it's not a problem).
  Future<bool> _loadEnvFromAsset({
    required String relativeFilePath,
    bool mayTheFileNotExist = false,
  }) async {
    // Before try to load the file given, the dotenv.load method cleans the env.map; therefore if
    // the file doesn't exist or it's empty, all the previous loaded elements are lost.
    // That's why we test if the file exists or it's empty before trying to load it
    String? fileContent;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      fileContent = await rootBundle.loadString(relativeFilePath);
    } catch (error) {
      // The file doesn't exist or a problem occurred
    }

    if (fileContent == null) {
      if (!mayTheFileNotExist) {
        _logsHelper.w("Can't load asset file: $relativeFilePath, it doesn't exist");
        return false;
      }

      return true;
    }

    if (fileContent.isEmpty) {
      // The file exists but it's empty; the lib throws an error in this case (and cleans the env
      // map before)
      // Nothing has to be done
      return true;
    }

    final lines = LineSplitter.split(fileContent);

    final globalElements =
        dotenv.isInitialized ? Map<String, String>.from(dotenv.env) : <String, String>{};

    globalElements.addAll(const Parser().parse(lines));

    var success = true;

    try {
      dotenv.testLoad(mergeWith: globalElements);
    } catch (error) {
      success = false;
      _logsHelper.w("A problem occurred when tried to load the env file: $relativeFilePath, "
          "error: $error");
    }

    return success;
  }
}

/// [NotNullableEnvVar] wraps a single environment variable of type T, providing strongly-typed
/// read helper.
///
/// If the env variable isn't defined in the environment, [load] method returns [defaultValue]
class NotNullableEnvVar<T> extends _AbsEnvVar<T> {
  /// The default value to use when nothing is got from dotenv
  final T defaultValue;

  /// Class constructor
  /// If [defaultValue] isn't null, this value will be returned when null is got from dotenv.
  NotNullableEnvVar(
    super.key, {
    required this.defaultValue,
  });

  /// Load value from environment variable.
  ///
  /// If the env variable isn't defined in the environment, the method will return the
  /// [defaultValue]
  T load() => _load() ?? defaultValue;
}

/// [EnvVar] wraps a single environment variable of type T, providing strongly-typed read helper.
///
/// If the env variable isn't defined in the environment, [load] method returns null
class EnvVar<T> extends _AbsEnvVar<T> {
  /// Class constructor
  EnvVar(super.key);

  /// Load value from environment variable.
  ///
  /// If the env variable isn't defined in the environment, the method will return null
  T? load() => _load();
}

/// [_AbsEnvVar] wraps a single environment variable of type T, providing strongly-typed
/// read helper.
abstract class _AbsEnvVar<T> {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// Create a environment variable wrapper for key [key] of type T.
  _AbsEnvVar(this.key);

  /// Load value from environment variable.
  T? _load() {
    final value = dotenv.maybeGet(key);

    if (value == null) {
      return null;
    }

    switch (T) {
      case const (bool):
        return BoolHelper.tryParse(value) as T;
      case const (int):
        return int.tryParse(value) as T;
      case const (double):
        return double.tryParse(value) as T;
      case const (String):
        return value as T;
      default:
        // A _SecretItem<unsupported T> member was added to SecretsManager
        // Dear developer, please add the support for your specific T.
        appLogger().e('Unsupported type $T');
        throw Exception('Unsupported type $T');
    }
  }
}
