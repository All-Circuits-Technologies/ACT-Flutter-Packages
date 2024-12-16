// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Possible environments
enum Environment {
  local(name: "local"),
  defaultEnv(name: "default"),
  development(name: "development", parsedString: "DEV"),
  staging(name: "staging", parsedString: "STAGING"),
  production(name: "production", parsedString: "PROD");

  /// The env file name
  final String fileName;

  /// Contains the string used by the app builder to represent the targeted environment
  /// If null, it means that the environment can't be targeted
  final String? _parsedString;

  /// Get the env relative file path
  String get relFilePath => "$defaultConfigPath$fileName";

  /// Enum constructor
  const Environment({
    required String name,
    String? parsedString,
  })  : fileName = "$name$fileType",
        _parsedString = parsedString;

  /// Constants linked to Environment
  static const fileType = ".env";
  static const envType = "ENV";
  static const defaultConfigPath = "config/";

  /// Get [Environment] from [env] string
  ///
  /// By default we use the [Environment.development] environment
  static Environment fromString(String env) {
    final upEnv = env.toUpperCase();

    for (final tmpEnv in Environment.values) {
      if (tmpEnv._parsedString == upEnv) {
        return tmpEnv;
      }
    }

    return Environment.development;
  }
}
