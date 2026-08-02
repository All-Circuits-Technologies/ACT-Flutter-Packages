<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Launcher icon <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Create the images](#create-the-images)
  - [Generate the launcher icons](#generate-the-launcher-icons)
  - [Generate and configure the images yourself](#generate-and-configure-the-images-yourself)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
  - [Android adaptive foreground image too big](#android-adaptive-foreground-image-too-big)
- [Testing](#testing)

## Presentation

This package helps to generate launcher icons. It uses the package to do it:
[icons_launcher](https://pub.dev/packages/icons_launcher).

The icons are generated once, by a command run by a developer; nothing of this package runs when
the application does.

## Architecture

The package ships no Dart code: its library is empty and it exposes no class, no function and no
constant. All it does is bring `icons_launcher` and the version of it the ACT projects agree on, so
that a project which wants launcher icons depends on this package instead of pinning the tool
itself.

Everything a project needs is therefore the configuration described below and the command which
reads it.

## How to use

### Installation

This package has no need to be added in the `dependencies` of your project but has to be added in
`dev_dependencies`:

```yaml
dev_dependencies:
  act_launcher_icon:
    path: ../act_launcher_icon
```

### Create the images

The image size which will be used has to have a size of 1024px.

### Generate the launcher icons

Then you have to call the command at the project root:

```console
> dart run icons_launcher:create
```

or

```console
> dart run icons_launcher:create --path=icons_launcher.yaml
```

### Generate and configure the images yourself

It's also possible to generate the images yourself, for

- Android app see:
  [Android launcher icon](https://developer.android.com/studio/write/create-app-icons).
- iOS see: [iOS app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)

## Configuration

_We follow the doc here: [icons_launcher](https://pub.dev/packages/icons_launcher)._

To configure the adding of the launcher icons to the app, you have to add configuration to the
project `pubspec.yaml` (not the one of the package but the root one).

You may also create a file in the root folder: `icons_launcher.yaml`. The command then needs the
`--path` option to find it.

## Troubleshooting

### Android adaptive foreground image too big

When using the `adaptive_foreground_image` option for android, the icon in the image given has to
be smaller than twice of the size of the image.

For instance, if the image size is 1024px, the icon in the image has to be smaller than 612px.

## Testing

The package has no test, because it has no code to test: it only declares a dependency, and the
generation itself belongs to `icons_launcher`. It therefore has no `test` stage in the continuous
integration either, only the analysis every package goes through.
