<!--
SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart YAML utility <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [How to use](#how-to-use)
  - [From YAML objects to plain Dart ones](#from-yaml-objects-to-plain-dart-ones)
  - [From a string](#from-a-string)

## Presentation

This package contains pure Dart helpers to parse YAML content into plain Dart objects, the same
kind of objects `jsonDecode` returns. Because JSON is valid YAML, JSON content is parsed as well.

It has no dependency on Flutter, so it can be used from any Dart program (CLI, server, tests). To
read YAML from the Flutter assets bundle, see the `act_yaml_utility` package, which builds on this
one.

## How to use

### From YAML objects to plain Dart ones

`YamlToStandardObj` converts the objects of the `yaml` package (`YamlMap`, `YamlList`,
`YamlDocument`, ...) into plain Dart objects. This loses the YAML specifics like the comments.

### From a string

`YamlFromString` parses a YAML `String` and returns plain Dart objects: `fromYaml` returns any
value, `fromYamlMap` expects an object at the root, and `fromYamlList` expects a list at the root.
