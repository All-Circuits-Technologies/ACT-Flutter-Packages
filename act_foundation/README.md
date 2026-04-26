<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Foundation  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)

## Presentation

This package provides foundational classes and interfaces for the ACT packages, such as the logger
interface and errors.

This package is at the base of all the ACT packages and should not have any dependency on other ACT
packages.

It has to only contain simple classes and interfaces that can be used by all the other ACT packages.
Before adding a new class or interface to this package, you should ask yourself if it is really
useful for all the other ACT packages, and if it is not better to put it in a more specific package
but still generic (_such as `act_dart_utility` or `act_flutter_utility`_).
