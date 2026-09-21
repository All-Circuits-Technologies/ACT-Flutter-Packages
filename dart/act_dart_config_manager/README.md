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

### Loading the configuration from the file system

```dart
import 'package:act_dart_config_manager/file_config_loader.dart';

await FileConfigLoader.load(logger: logger);
```

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
