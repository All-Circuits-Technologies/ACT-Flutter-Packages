<!--
SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart utility <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Usage](#usage)

## Presentation

This package contains useful methods and classes which extends dart features.

## Usage

This packages mainly contains static constants and helpers grouped using
classes. All you need to use them is to import `act_dart_utility`:

```dart
import 'package:act_dart_utility/act_dart_utility.dart';
// ...
    var ok = StringUtility.isValidEmail(string);
```

This package also features types extensions. You must import them explicitly:

```dart
import 'package:act_dart_utility/act_dart_utility_ext.dart';
// ...
   var ok = string.isValidEmail();
```
