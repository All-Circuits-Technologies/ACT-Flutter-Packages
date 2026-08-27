<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen mobile  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Register the manager](#register-the-manager)
  - [Generate the native splash screens](#generate-the-native-splash-screens)
- [Troubleshooting](#troubleshooting)
  - [Android 12 - No icon when debugging or at first launch](#android-12---no-icon-when-debugging-or-at-first-launch)
- [Testing](#testing)

## Presentation

This package brings the splash screen manager of the Android and iOS applications. It completes
[act_splash_screen_manager_core](../act_splash_screen_manager_core/), which holds the first frame
back until the application is ready.

Android, the SplashScreen API of Android 12 and later included, and iOS remove their splash screen
by themselves as soon as the first frame is rendered. The manager therefore has nothing to ask
them: holding the first frame back is all these platforms need, and the whole initialization of the
application is covered by the splash screen the platform draws.

## How to use

### Installation

Add the package to the `dependencies` of your application, together with the core package, and the
generator to its `dev_dependencies`:

```yaml
dependencies:
  act_splash_screen_manager_core:
    path: ../act_splash_screen_manager_core
  act_splash_screen_manager_mobile:
    path: ../act_splash_screen_manager_mobile

dev_dependencies:
  flutter_native_splash: ^2.4.8
```

### Register the manager

```dart
registerManagerAsync<AbsSplashScreenManager>(const MobileSplashScreenBuilder());
```

The call belongs to the `registerManagers` method of the global manager of the application, and the
registered type is `AbsSplashScreenManager`, the one every family shares.

Nothing else is needed: the manager is initialized with the others, and the first view removes the
splash screen through `initInFirstView` of the global manager.

### Generate the native splash screens

_The steps below follow the documentation of
[flutter_native_splash](https://pub.dev/packages/flutter_native_splash)._

The splash screen is described in the `pubspec.yaml` of the application, or in a
`flutter_native_splash.yaml` file at its root. The parameters of Android 12 and later live in their
own `android_12` section, because these versions handle splash screens differently.

Then generate the native files, from the root of the application:

```console
> dart run flutter_native_splash:create
```

or

```console
> dart run flutter_native_splash:create --path=flutter_native_splash.yaml
```

The generated files belong to the application and are version controlled with it. Run the command
again whenever the image or the colours change.

## Troubleshooting

### Android 12 - No icon when debugging or at first launch

This problem has already been noticed by aloiseau (2023/04/11):

> Note: Splash screen logo is not shown on very first app execution. Is is however properly
> displayed on subsequent launches of the app. Also, Samsung UI make logo readable but a little bit
> small.

Because when you debug, you install a new app, it's considered as a first launch.

## Testing

The tests check that the manager is one of the family and that it holds the first frame back until
the first view is built. That it asks the platform nothing is what the platform expects, so there
is nothing else to observe.

```console
> flutter test
```
