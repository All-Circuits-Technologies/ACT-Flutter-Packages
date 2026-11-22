<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart config manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to use](#how-to-use)
  - [Reading config variables](#reading-config-variables)
  - [Choosing a config manager](#choosing-a-config-manager)
  - [Loading the configuration from the file system](#loading-the-configuration-from-the-file-system)
  - [Loading the configuration from another source](#loading-the-configuration-from-another-source)

## Presentation

This package contains pure Dart helpers to manage config variables. It holds everything the
configuration needs once its content is in hand: the typed config variable wrappers, the store the
wrappers read from, the environment types, and the parsers which turn the raw content of the config
files, the env config mapping file and the dot env file into a structured config.

Because it's pure Dart, it doesn't know where the content comes from. Two ways to feed it are
provided:

- `FileConfigLoader` reads the files from a directory of the file system. It's exposed through the
  separate `file_config_loader.dart` entry point because it relies on `dart:io`, which isn't
  available on the web.
- the parsers (`ConfigFileParser`, `EnvConfigMappingParser`, `ConfigFromEnv`, `DotEnvParser`) work
  on strings and maps, so any host can gather the content its own way (for instance the Flutter
  `act_config_manager` package reads it from the assets bundle) and fill the `ConfigStore` with it.

## How to use

### Reading config variables

Declare the variables the application reads, then load them once the store has been created:

```dart
const serverPort = NotNullableConfigVar<int>("server.port", defaultValue: 50000);

final port = serverPort.load();
```

### Choosing a config manager

The package provides the base of the config managers, which creates the `ConfigStore` when the
manager is initialized and releases it when the manager is disposed:

- `AbsCoreConfigManager` is the shared base. It holds the environment (`env`), asks the derived class
  to load the configuration (`loadConfigs()`), and creates the store from it. It doesn't know where
  the configuration comes from. It is mainly the type the mixins which declare config variables
  target, so they work with every config manager;
- `AbsFileConfigManager` derives from it and reads the configuration from the file system, through
  `FileConfigLoader`. It is the manager to derive in a pure Dart application (a server, a script).
  It is exported by `file_config_loader.dart`, not by the main entry point, because it relies on
  `dart:io`;
- `AbstractConfigManager` of the Flutter `act_config_manager` package derives from it too and reads
  the configuration from the assets of a Flutter application. A Flutter application derives that
  one, or `AbsUsualConfigManager` of `act_global_manager`.

`AbsCoreConfigBuilder` is the builder to register such a manager, it depends on no other manager.

```dart
import 'package:act_dart_config_manager/file_config_loader.dart';

class AppConfigManager extends AbsFileConfigManager {
  final serverPort = const NotNullableConfigVar<int>("server.port", defaultValue: 50000);

  AppConfigManager({required super.logger, super.configDir, super.env});
}
```

The directory and the environment follow the rules of `FileConfigLoader`, described below.

### Loading the configuration from the file system

```dart
import 'package:act_dart_config_manager/file_config_loader.dart';

await FileConfigLoader.load(logger: logger);
```

`FileConfigLoader.loadConfigs` does the same without creating the store: it returns the merged
configuration, which is what `AbsFileConfigManager` hands to the store. `resolveEnvironment` returns
the environment the `ENV` environment variable targets.

The directory the files are read from is the one given to `load`, else the value of the
`ACT_CONFIG_DIR` environment variable, else `config`. The environment is the one given to `load`,
else the one the `ENV` environment variable targets, else the development one. This lets the
configuration be changed without recompiling the host.

### Loading the configuration from another source

Gather the content of the files, parse it with the parsers, merge the results and create the store:

```dart
final fileConfig = ConfigFileParser.fromContent(defaultContent, description: "default");
final mapping = EnvConfigMappingParser.fromContent(mappingContent);
final envConfig = ConfigFromEnv.parse(mapping: mapping, processEnv: {}, dotEnv: {});

ConfigStore.create(logger: logger, configs: {...fileConfig, ...envConfig});
```
