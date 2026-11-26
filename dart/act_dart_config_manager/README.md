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
  - [Loading the configuration from another source](#loading-the-configuration-from-another-source)

## Presentation

This package contains pure Dart helpers to manage config variables: the typed config variable
wrappers, the store the wrappers read from, the environment types, the parsers which turn the raw
content of the config files, the env config mapping file and the dot env file into a structured
config, and the `ConfigLoader` which reads, parses and merges them.

Because it's pure Dart, it doesn't know where the files are. `ConfigLoader` reads them through an
`AbsConfigReader`, which each host derives to read them its own way (for instance the Flutter
`act_config_manager` package reads them from the assets bundle).

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
- `AbstractConfigManager` of the Flutter `act_config_manager` package derives from it and reads
  the configuration from the assets of a Flutter application. A Flutter application derives that
  one, or `AbsUsualConfigManager` of `act_global_manager`.

`AbsCoreConfigBuilder` is the builder to register such a manager, it depends on no other manager.

### Loading the configuration from another source

Derive `AbsConfigReader` to tell where the files are, then let `ConfigLoader` read, parse and merge
them, and create the store:

```dart
class MyConfigReader extends AbsConfigReader {
  const MyConfigReader();

  @override
  String locate(String fileName) => "config/$fileName";

  @override
  Future<String?> readRaw(String location) async => myStorage.read(location);
}

final configs = await ConfigLoader.loadConfigs(
  reader: const MyConfigReader(),
  env: Environment.production,
  processEnv: const {},
);

ConfigStore.create(logger: logger, configs: configs);
```

The loader looks for the `default`, environment and `local` config files and for the
`env_config_mapping` file with the `yaml`, `yml` then `json` type, and for the `.env` file. A missing
file is skipped.
