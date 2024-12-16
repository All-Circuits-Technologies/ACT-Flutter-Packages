<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Launcher icon  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Dev dependencies](#dev-dependencies)
- [Generate and configure the images yourself](#generate-and-configure-the-images-yourself)
- [How to add a launcher icon to the app](#how-to-add-a-launcher-icon-to-the-app)
  - [Initialization](#initialization)
  - [Create the images](#create-the-images)
  - [Generate the launcher icons](#generate-the-launcher-icons)
- [Troubleshooting](#troubleshooting)
  - [Android adaptive foreground image too big](#android-adaptive-foreground-image-too-big)

## Presentation

This package helps to generate launcher icons. It uses the package to do it:
[icons_launcher](https://pub.dev/packages/icons_launcher).

## Dev dependencies

This package has no need to be added in the `dependencies` of your project but has to be added in
`dev_depedencies`.

## Generate and configure the images yourself

It's also possible to generate the images yourself, for

- Android app see:
  [Android launcher icon](https://developer.android.com/studio/write/create-app-icons).
- iOS see: [iOS app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)

## How to add a launcher icon to the app

### Initialization

_We follow the doc here: [icons_launcher](https://pub.dev/packages/icons_launcher)._

To configure the adding of the launcher icons to the app, you have to add configuration to the
project `pubspec.yaml` (not the one of the package but the root one).

You may also create a file in the root folder: `icons_launcher.yaml`.

### Create the images

The image size which will be used has to have a size of 1024px.

### Generate the launcher icons

Then you have to call the command at the project root:

> dart run icons_launcher:create

or

> dart run icons_launcher:create --path=icons_launcher.yaml

## Troubleshooting

### Android adaptive foreground image too big

When using the `adaptive_foreground_image` option for android, the icon in the image given has to
be smaller than twice of the size of the image.

For instance, if the image size is 1024px, the icon in the image has to be smaller than 612px.
