<!--
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Entity <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Write an entity](#write-an-entity)
  - [Read an entity back from JSON](#read-an-entity-back-from-json)
- [Testing](#testing)

## Presentation

This package contains the entity base class for models.

An entity is a model exchanged with a server: it knows how to turn itself into JSON, how to fill
itself from JSON, and whether what it holds is complete enough to be used.

The package only carries that contract. It does not encode nor decode JSON, does not talk to a
server, and does not validate anything by itself: every entity says what valid means for it.

## Architecture

The whole package is the `Entity` mixin, with three members:

| Member          | Left to the entity | Role                                             |
| --------------- | ------------------ | ------------------------------------------------ |
| `toJson`        | yes                | Builds the JSON map sent to the server           |
| `isValid`       | yes                | Says whether the entity holds what it needs      |
| `parseFromJson` | no, does nothing   | Fills the entity from a JSON map                 |

`parseFromJson` has an empty implementation, so an entity which is only ever sent to a server has
nothing to write. An entity which is also received from one overrides it.

The mixin says nothing about the shape of the JSON map, so nested entities are the business of the
entity which holds them.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_entity:
    path: ../act_entity
```

### Write an entity

```dart
class User with Entity {
  String? name;
  int? age;

  @override
  bool get isValid => name != null && age != null;

  @override
  Map<String, dynamic> toJson() => {"name": name, "age": age};
}
```

### Read an entity back from JSON

An entity which is received from a server also overrides `parseFromJson`:

```dart
@override
void parseFromJson(Map<String, dynamic> json) {
  name = json["name"] as String?;
  age = json["age"] as int?;
}
```

The caller checks `isValid` before using what it parsed:

```dart
final user = User()..parseFromJson(json);
if (!user.isValid) {
  return const ResultWithBoolStatus(status: BoolResultStatus.error);
}
```

## Testing

The tests cover the members the mixin leaves to the entity, the empty `parseFromJson` an entity
gets when it does not override it, and the round trip between `toJson` and an overridden
`parseFromJson`.

```console
> flutter test
```
