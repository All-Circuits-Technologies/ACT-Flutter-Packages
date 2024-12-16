<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Splash screen  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to add a splash screen to the app](#how-to-add-a-splash-screen-to-the-app)
  - [Initialization](#initialization)
- [Troubleshooting](#troubleshooting)
  - [Android 12 - No icon when debugging or at first launch](#android-12---no-icon-when-debugging-or-at-first-launch)

## Presentation

This package helps to support native splash screen. It uses the package to do it:
[flutter_native_splash](https://pub.dev/packages/flutter_native_splash).

## How to add a splash screen to the app

### Initialization

_We follow the doc here: [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)._

To configure the adding of the splash screen to the app, you have to add configuration to the
project `pubspec.yaml` (not the one of the package but the root one).

You may also create a file in the root folder: `flutter_native_splash.yaml`.

Then you have to call the command at the project root:

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
