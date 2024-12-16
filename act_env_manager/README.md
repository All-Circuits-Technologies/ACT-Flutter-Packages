<!--
SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Env manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to use](#how-to-use)

## Presentation

This package contains methods to manage environment variables.

## How to use

To choose the environment in flutter run/build, use the parameter "--dart-define"

Example:

> flutter run --dart-define="ENV=PROD".

Possible values are : `DEV`, `STAGING` and `PROD`.
