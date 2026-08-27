<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [The packages of the family](#the-packages-of-the-family)
- [How to use](#how-to-use)
- [Testing](#testing)

## Presentation

This package keeps the native splash screen of an application displayed until its first view is
built, whatever the platform the application runs on. It brings the packages of every family of
platforms and picks the right one at runtime.

It is the package to depend on when an application targets several families at once. **An
application which targets a single family is better off depending on
[act_splash_screen_manager_core](../act_splash_screen_manager_core/) and on the package of that
family**: it brings what it uses, and nothing else appears in its dependencies. Never depend on
both this package and the core one, they export the same names.

## The packages of the family

| Package                                        | Platforms    | What it does                                                     |
| ---------------------------------------------- | ------------ | --------------------------------------------------------------- |
| [core](../act_splash_screen_manager_core/)     | all          | holds the first frame back until the application is ready        |
| [mobile](../act_splash_screen_manager_mobile/) | Android, iOS | nothing to ask: the platform removes its splash screen by itself |
| [web](../act_splash_screen_manager_web/)       | web          | asks the generated page to remove the splash screen             |
| [desktop](../act_splash_screen_manager_desktop/) | Linux | asks the runner of the application to remove the splash screen it draws |

More families join the table as their packages are added. Each of them says how the splash screen
of its platforms is described and generated, which is not the same work from one to the other. Read
the one of every platform your application targets.

## How to use

Add the package to the `dependencies` of your application:

```yaml
dependencies:
  act_splash_screen_manager:
    path: ../act_splash_screen_manager
```

Then register the builder, which needs to be told nothing:

```dart
registerManagerAsync<AbsSplashScreenManager>(const SplashScreenBuilder());
```

The manager which is built is the one of the platform the application runs on. Everything else -
the images, the configuration, the generated files - belongs to the package of each platform.

## Testing

The tests check that the builder depends on the logger manager and builds the manager of the
platform the application runs on.

```console
> flutter test
```
