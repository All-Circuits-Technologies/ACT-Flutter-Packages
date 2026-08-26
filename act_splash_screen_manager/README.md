<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Generate the native splash screens](#generate-the-native-splash-screens)
- [Troubleshooting](#troubleshooting)
  - [Android 12 - No icon when debugging or at first launch](#android-12---no-icon-when-debugging-or-at-first-launch)
- [Testing](#testing)

## Presentation

This package keeps the native splash screen of an application displayed until its first view is
built.

The splash screen the platform displays is removed as soon as Flutter is ready, which is before the
managers of the application are. Without this manager, the application shows an empty screen during
that time; with it, the splash screen covers the whole initialization.

The package does not draw the splash screen and does not generate it either: the images and the
colours belong to the configuration of
[flutter_native_splash](https://pub.dev/packages/flutter_native_splash), which this manager only
drives.

## Architecture

`SplashScreenManager` is a manager with the life cycle of the views, and it does one thing at each
of its two steps:

- when it is initialized, it holds the first frame back, which leaves the native splash screen on
  the screen,
- when the first view is built, it lets the frames through, which removes it.

`SplashScreenBuilder` is the factory to register it with. It depends on the logger manager, so that
the messages of the initialization it covers are already written where the application writes them.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_splash_screen_manager:
    path: ../act_splash_screen_manager
```

### Register the manager

```dart
GlobalManager.instance.register(SplashScreenBuilder());
```

Nothing else is needed: the manager is initialized with the others, and the first view removes the
splash screen through `initInFirstView` of the global manager.

### Generate the native splash screens

_The steps below follow the documentation of
[flutter_native_splash](https://pub.dev/packages/flutter_native_splash)._

The splash screen is described in the `pubspec.yaml` of the application, not in the one of this
package, or in a `flutter_native_splash.yaml` file at the root of the application.

Then generate the native files, from the root of the application:

> dart run flutter_native_splash:create

or

> dart run flutter_native_splash:create --path=flutter_native_splash.yaml

## Troubleshooting

### Android 12 - No icon when debugging or at first launch

This problem has already been noticed by aloiseau (2023/04/11):

> Note: Splash screen logo is not shown on very first app execution. Is is however properly
> displayed on subsequent launches of the app. Also, Samsung UI make logo readable but a little bit
> small.

Because when you debug, you install a new app, it's considered as a first launch.

## Testing

The tests drive the manager through its two steps and read the binding of the test to check what an
application would see: the frames are held back once the manager is initialized, and they are let
through once the first view is built. A manager which is asked to remove a splash screen it never
preserved is covered too.

The images and the native files are out of reach of a test: they are generated at build time, by the
package this one drives.

```console
> flutter test
```
