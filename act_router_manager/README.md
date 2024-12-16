<!--
SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Router Manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Be careful](#be-careful)

## Presentation

This package contains a router manager.

## Be careful

With GoRouter at least at version `13.2.1`, the automatic orientation update doesn't work with
GoRouter `replace` method.

We temporally fix this problem in the manager. That's why we strongly advise to use the push, pop,
replace methods of the `AbstractGoRouterManager` instead of using directly the methods of
`GoRouter`.
