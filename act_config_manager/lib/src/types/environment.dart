// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Possible environments to use
enum Environment {
  local(fileName: "local"),
  defaultEnv(fileName: "default"),
  development(fileName: "development", parsedString: "DEV"),
  qualification(fileName: "qualification", parsedString: "QUALIF"),
  production(fileName: "production", parsedString: "PROD");

  /// The env file name
  final String fileName;

  /// Contains the string used by the app builder to represent the targeted environment.
  ///
  /// If null, it means that the environment can't be targeted at build time.
  final String? parsedString;

  /// Enum constructor
  const Environment({
    required this.fileName,
    this.parsedString,
  });

  /// Constants linked to Environment
  static const envType = "ENV";

  /// Get [Environment] from [env] string
  ///
  /// By default we use the [Environment.development] environment
  static Environment fromString(String env) {
    final upEnv = env.toUpperCase();

    for (final tmpEnv in Environment.values) {
      if (tmpEnv.parsedString == upEnv) {
        return tmpEnv;
      }
    }

    return Environment.development;
  }
}
