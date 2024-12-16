<!--
SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Act Storage Manager <!-- omit from toc -->

This packages facilitates the management of storage in Flutter applications.

## Table of contents <!-- omit from toc -->

- [Features](#features)
- [Documentation](#documentation)

## Features

This packages helps you to:

- Download files from the internet.
- Cache files on the device so that they are downloaded only when needed.

## Documentation

Here is a class diagram of the package:

![class diagram](doc/class_diagram.png)

The global idea is the following: The `AbsStorageManager` must be implemented and requires a
concrete class which extends the `MixinStorageService` to provide basic storage operation.
The `AbsStorageManager` also embeds a `CacheService` which is responsible for caching
some files on the device. We use [this library](https://pub.dev/packages/flutter_cache_manager) to
handle the logic of caching files.

To use this package you need to:

- Implement a class which extends the `MixinStorageService` class.
- Create a `StorageManager` class which feeds the `AbsStorageManager` with the implementation of the
  `MixinStorageService` class.
- Use the `StorageManager` to download and cache files.
