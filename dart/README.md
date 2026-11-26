<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Pure Dart packages

The packages of this folder do not depend on Flutter: they are usable from a script, a server or
tests on the Dart VM, as well as from a Flutter application. The [main README](../README.md)
explains the split with the [`flutter/`](../flutter/README.md) folder.

| Package                                                       | Description                                                                                                                                              | Version |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| [act_dart_config_manager](act_dart_config_manager/)           | This package contains pure Dart helpers to manage config variables from their content and, optionally, from the file system.                             |         |
| [act_dart_life_cycle](act_dart_life_cycle/)                   | This package contains a life cycle pattern implementation to manage the life cycle of classes and their dependencies, without any dependency on Flutter. |         |
| [act_dart_result](act_dart_result/)                           | This package provides a way to represent the result of a request with a status and the actual value of the request.                                      |         |
| [act_dart_test_utility](act_dart_test_utility/)               | This package contains shared fakes and helpers to write the unit tests of the pure Dart ACT packages, without a dependency on Flutter.                   |         |
| [act_dart_timer](act_dart_timer/)                             | This package provides a way to create timers that can be restarted and that can have a progressing duration.                                             |         |
| [act_dart_utility](act_dart_utility/)                         | This package contains useful methods and classes which extends dart functionality.                                                                       |         |
| [act_dart_value_keeper](act_dart_value_keeper/)               | This package provides a way to keep a value and update it based on a stream or an initialization function.                                               |         |
| [act_dart_yaml_utility](act_dart_yaml_utility/)               | This package contains pure Dart helpers to parse YAML content (and JSON, which is valid YAML) into plain Dart objects.                                   |         |
| [act_entity](act_entity/)                                     | This package contains the entity base class for models.                                                                                                  |         |
| [act_foundation](act_foundation/)                             | This package provides foundational classes and interfaces for the ACT packages, such as the logger interface and errors.                                 |         |
| [act_http_core](act_http_core/)                               | This package contains the core HTTP functionalities                                                                                                      |         |
| [act_launcher_icon](act_launcher_icon/)                       | Useful package to generate launcher icons for the apps                                                                                                   |         |
| [act_tic_manager](act_tic_manager/)                           | This package contains a tic manager which helps to display HMI in pace                                                                                   |         |
