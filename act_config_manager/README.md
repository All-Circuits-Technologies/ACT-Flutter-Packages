<!--
SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Config manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to add config variables](#how-to-add-config-variables)
  - [Storage](#storage)
  - [How it works](#how-it-works)
    - [1. Default config file](#1-default-config-file)
    - [2. Environment config files](#2-environment-config-files)
    - [3. Local config files](#3-local-config-files)
    - [4. Environment variables and mapping](#4-environment-variables-and-mapping)
      - [4.1. Mapping with env variables](#41-mapping-with-env-variables)
      - [4.2. Use env variables](#42-use-env-variables)
        - [4.2.1. Presentation](#421-presentation)
        - [4.2.2. Env variables set at build time](#422-env-variables-set-at-build-time)
        - [4.2.3. Env variables of the OS](#423-env-variables-of-the-os)
      - [4.3. Use `.env` file](#43-use-env-file)
  - [Environment](#environment)
  - [The precedence](#the-precedence)
- [How to use the config variables](#how-to-use-the-config-variables)

## Presentation

This package contains methods to manage config variables. This package manages three different
environments:

- production,
- qualification, and
- development.

You may have different config values for each environment.

## How to add config variables

### Storage

The configuration files have to be stored in the assets folder of your project in a `assets/config/`
folder.

The folder has to be added in the assets of the `pubspec.yaml` of the main project (to be usable
by the app after the build).

In this folder, you store config files, which are yaml or json files.

But you may also store a local `.env` files to override env variables.

### How it works

#### 1. Default config file

The package takes the default config file, which contains all the default values for the config
variables. The file name must be `default.*` _(e.g. default.yaml or default.json ...)_.

#### 2. Environment config files

Then, the package takes the config file which matches the current environment (production,
qualification or development). The files name have to be:

- `development.*` for development env _(e.g. development.yaml or development.json ...)_,
- `qualification.*` for qualification env _(e.g. qualification.yaml or qualification.json ...)_, and
- `production.*` for production env _(e.g. production.yaml or production.json ...)_.

The values stored in the env files overrides the values of the default file.

#### 3. Local config files

If you don't want to commit some configs, you can use a `local.*` _(e.g. local.yaml or local.json
...)_ file which will contain configuration only used in your PC.

#### 4. Environment variables and mapping

##### 4.1. Mapping with env variables

Then the package takes the env variables. To match the environment variables with the config
variables you have to create a "mapping" file, which is named: `env_config_mapping.*`
_(e.g. env_config_mapping.yaml or env_config_mapping.json ...)_. The file may be a yaml or json
file.

To add a matching between a conf variable and an env variable, you have to copy the config files
structure and write the name of the env variable you want instead of the conf value. For instance,
you have this config in your `default.yaml` file:

```yaml
logs:
  level: warning
  enable: true
  logsNb: 3
```

To create an env variable, in the env config mapping file, you have to replace the value by the name
of the env variable you want. For instance:

```yaml
logs:
  level: LOGS_LEVEL
```

In the case, the env variable replaces a boolean, number or yaml, you may precise the format type,
like this:

```yaml
logs:
  level:
    __name: LOGS_LEVEL
    __format: string
  enable:
    __name: LOGS_ENABLE
    __format: boolean
  logsNb:
    __name: LOGS_NB
    __format: number
```

##### 4.2. Use env variables

###### 4.2.1. Presentation

With Flutter apps, there are two kinds of environment variables:

- The environment variables set at build time
- The environment variables of the OS

###### 4.2.2. Env variables set at build time

Those are the env variables set when the app is built (through the command argument:
`--dart-define`). For instance:

> `flutter build --dart-define="LOGS_LEVEL=warning"`

###### 4.2.3. Env variables of the OS

Those are the env variables retrieved from the OS.

##### 4.3. Use `.env` file

In local you may create a `.env` file which is a property file and contain env values to use. For
instance:

```ini
LOGS_LEVEL=warning
LOGS_ENABLE=true
LOGS_NB=4
```

### Environment

To choose the environment in flutter run/build, use the parameter "--dart-define"

Example:

> flutter run --dart-define="ENV=PROD".

Possible values are : `DEV`, `QUALIF` and `PROD`.

### The precedence

The following conf variables are overridden in this order (from the less to the more important):

1. `default.*`
2. `production.*`, `qualification.*` or `development.*`
3. `local.*` (_not committed_)
4. OS/Runtime env variables
5. Build env variables
6. `.env` file (_not committed_)

The build env variables are more important than the OS env variables, because some env variables
should be shared between some OS applications and we want to be able to override those values.

## How to use the config variables

To use the config variables, you have to use the classes which derived from the `AbsConfigVar`
class.

The class takes a `key`. This key is the path to get the variable you want separated by dot. For
instance, if you have the following config file:

```yaml
logs:
  level: warning

firebase:
  crash:
    enable: false
    autoLogEnable: false
```

To access the variables, you have to use the following keys:

- `logs.level`
- `firebase.crash.enable`
- `firebase.crash.autoLogEnable`
