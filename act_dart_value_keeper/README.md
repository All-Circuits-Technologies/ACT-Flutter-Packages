<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart Value keeper <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)

## Presentation

This package provides a way to keep a value and update it based on a stream or an initialization
function.

The main goal is to have a unified way to have an object to keep a value in the codebase.

Thanks to this package, we can have a value that is automatically updated based on a stream and
which emits an event when the value is updated.
