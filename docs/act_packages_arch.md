<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Packages Architecture  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Overview](#overview)
- [Architecture principles](#architecture-principles)
- [Main layers](#main-layers)

## Overview

This document describes the architecture of the ACT packages, which are a collection of Flutter
packages developed by AllCircuits.

The ACT packages are designed to provide a consistent and modular approach to building Flutter
applications. They are organized into several layers, each with a specific responsibility.

It uses various external packages and create a layer of abstraction to provide a consistent API and
behavior across all packages, while allowing for flexibility and customization when needed.

Therefore, by design, the ACT packages are not meant to be used alone but rather as part of a larger
ecosystem of packages that work together to provide a complete solution for building Flutter
applications.

## Architecture principles

The ACT packages are designed with the following principles in mind:

- **Reusable, *but limited to what we need***: The packages are designed to be reusable across
  different projects and contexts. However, we don't develop code we don't use and test in real
  projects. If we write it, we know it works and we can maintain it.
- **Modular**: The packages are organized into layers, each with a specific responsibility. We try
  to avoid interdependencies between layers, and prefer to create interfaces and abstractions to
  decouple them.
- **Multi platforms**: The packages are designed to work in different platforms, such as mobile,
  web, and desktop (*with some exceptions: some packages, by design, are only meant to be used in
  specific platforms, such as mobile or web, and may not be compatible with other platforms*).
  However, as described in the previous point, we don't develop code we don't use and test in real
  projects, so if a package is only used in mobile projects, it will be designed and tested for
  mobile platforms; and if we need to use it in web projects, we will adapt it and also test it for
  web platforms.
- **Managers**: The packages are designed to work with managers. A manager is a class that is
  responsible for managing a specific aspect of the application, such as state management,
  navigation, or data fetching. All the managers are created by the GlobalManager, which is a
  singleton. The managers can be dependent on each other.

## Main layers

The ACT packages are organized into the following main base layers:

- [act_dart_utility](act_dart_utility/README.md): A collection of utility functions and classes for
  Dart programming.
- [act_flutter_utility](act_flutter_utility/README.md): A collection of utility functions and classes
  for Flutter development.
