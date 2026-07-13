<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart Value keeper <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Good to know](#good-to-know)

## Presentation

This package provides a way to keep a value and update it based on a stream or an initialization
function.

The main goal is to have a unified way to have an object to keep a value in the codebase.

Thanks to this package, we can have a value that is automatically updated based on a stream and
which emits an event when the value is updated.

## Good to know

The base of value keeper is the `ValueKeeper` class. This class is based on a getter
which can be null but not the setter.

In old dart version, this will raise the following error: `The setter 'value' has no
corresponding getter.`, but in dart 3.11, this is not the case anymore and it is possible to have a
setter without a getter.

Therefore, to use this package, you need to have a dart version superior to 3.11.1.
