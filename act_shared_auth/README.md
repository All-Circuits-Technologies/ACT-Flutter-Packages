<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Shared authentication  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)

## Presentation

The goal of this package is to abstract the call of user authentication service: to have always the
same methods, the same way to store information, etc.

Therefore, if you change the authentication service, even if the low level code change, you won't
need to update all the caller classes (BLoC, views, other managers, etc.).

When another manager needed to know if the user is authenticated it will go through the classes
created here and not the specific classes.
