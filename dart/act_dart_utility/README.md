<!--
SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Dart utility <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The two libraries](#the-two-libraries)
  - [Helpers](#helpers)
  - [Models](#models)
  - [Mixins](#mixins)
  - [Watchers and observers](#watchers-and-observers)
- [Usage](#usage)
  - [Read a JSON object](#read-a-json-object)
  - [Encode a number for a device](#encode-a-number-for-a-device)
  - [Protect a critical section](#protect-a-critical-section)
  - [Wait for a status](#wait-for-a-status)
  - [Watch a shared resource](#watch-a-shared-resource)
  - [Parse an enum from a value](#parse-an-enum-from-a-value)
- [Testing](#testing)

## Presentation

This package contains useful methods and classes which extends dart features.

Everything here is generic: nothing knows about an application, a server or a device. A helper which
would only make sense for one of them belongs to the package which owns it.

The package is a leaf of the ACT tree: it only depends on `act_foundation`, and it takes a logger
through the interface of that package rather than writing anywhere itself. Most helpers which can
fail take an optional logger and return `null` instead of throwing, so a caller decides what a
failure means.

## Architecture

### The two libraries

The package ships two libraries, and the split is deliberate: a type extension is visible on every
value of that type, so it is only brought in by the files which want it.

```dart
import 'package:act_dart_utility/act_dart_utility.dart';      // helpers, models, mixins
import 'package:act_dart_utility/act_dart_utility_ext.dart';  // type extensions
```

The extensions add nothing of their own: each one forwards to the helper of the same name. A new
behaviour is written in the helper, and only then mirrored in the extension.

### Helpers

The helpers are `sealed` classes of static methods, one per subject:

| Class                    | Subject                                                        |
| ------------------------ | -------------------------------------------------------------- |
| `StringUtility`          | Validation, capitalization, parsing, MAC addresses, hexadecimal |
| `StringListUtility`      | Trimming the empty strings of a list                            |
| `BoolUtility`            | The parsing Dart does not give to `bool`                        |
| `NumUtility`             | Turning a decimal number into an integer for a device           |
| `ByteUtility`            | Integer limits, LSB and MSB byte lists, hexadecimal             |
| `MathUtility`            | Degrees and radians                                             |
| `Base64Utility`          | Decoding a base64 value, wrapped or not                         |
| `CryptoUtility`          | Random strings                                                  |
| `TypeUtility`            | Testing the type of a value against a `Type`                    |
| `PathUtility`            | File extensions                                                 |
| `UriUtility`             | Building paths and appending segments to a uri                  |
| `MapUtility`             | Copying and merging maps                                        |
| `ListUtility`            | Copying, slicing, interleaving, indexing and moving elements    |
| `IterableUtility`        | What of the above applies to any iterable                       |
| `ComparableUtility`      | Comparing values which may be null, and booleans                |
| `JsonUtility`            | Reading a JSON object field by field, and merging two of them   |
| `DateTimeUtility`        | Building dates from epochs, parsing, ages                       |
| `DurationUtility`        | Formatting and parsing durations and time zone offsets          |
| `AssetsBundleUtility`    | Reading a file of the assets bundle                             |
| `FutureUtility`          | Aggregating the results of several futures                      |
| `LoopUtility`            | Gathering a whole collection through paged requests             |
| `LockUtility`            | Serialising the accesses to a resource                          |
| `WaitUtility`            | Waiting for a status on a stream                                |

The result of a call which can fail takes one of two shapes: `null` when the failure needs no
explanation, and a record `(isOk: bool, value: T?)` when a missing value and a failure have to be
told apart, which is what `JsonUtility` needs for the fields which are allowed to be absent.

`ByteUtility` offers each conversion twice: the checked one returns `null` when what is asked makes
no sense, and the `unsafe` one skips the checks for a caller which has already made them.

### Models

`SemanticVersion` parses, compares and writes a version as defined by semver, with its optional
prerelease and build metadata parts.

The boundaries describe a range a value has to fall in. `CustomComparableBoundaries` is the general
one and takes the nullability of each bound as a type parameter; the eight concrete classes name the
combinations which are actually used:

| Bound which may be null | On any comparable                  | On numbers                 |
| ----------------------- | ---------------------------------- | -------------------------- |
| None                    | `ComparableBoundaries`             | `NumBoundaries`            |
| The minimum             | `NullableMinComparableBoundaries`  | `NullableMinNumBoundaries` |
| The maximum             | `NullableMaxComparableBoundaries`  | `NullableMaxNumBoundaries` |
| Both                    | `NullableComparableBoundaries`     | `NullableNumBoundaries`    |

A missing bound is not tested at all, an assertion refuses a minimum greater than its maximum, and
`isInBoundaries` accepts the bounds themselves unless it is asked for a strict comparison.

`StringInterval` and `StringIntervalUtility` cut a text into intervals around a set of keys, so that
a caller can act on the parts which match and on the parts which do not. Every character ends up in
exactly one interval, and the last key of the list wins where two keys overlap.

`UpdatedModelEvent` describes what happened to a model: which of the creation, the update and the
deletion it is follows from the presence of the previous identifier and of the current object.
`UpdatedUniqueModelEvent` takes that identifier from the model itself.

### Mixins

`MixinStringValueType` and `MixinUniqueValueType` give an enum a value it can be parsed from, a
string for the first and anything for the second, which is what an enum read from JSON or from a
protocol needs. `MixinExtendsEnum` merges an enum of shared values with an enum of specific ones,
each specific value saying where it belongs in the merged list.

`MixinUniqueModel` gives a model an identifier which is not its equality,
`MixinOtherToMergeWithModel` gives it a merge with another type, and
`MixinComparableObjectAttribute` turns the properties of a model into the sort orders of a list of
them.

### Watchers and observers

`SharedWatcher` counts the handlers which need a shared resource, and calls `atFirstHandler` and
`whenNoMoreHandler` around them, so a feature is only running while someone uses it. Its
`thresholdDuration` delays the release, which avoids stopping and starting again a resource which is
handed over from one holder to the next. `OnReleaseWatcher` is the ready made one which calls a
callback at the release, and its `supervise` closes the handler even when the critical section
throws.

`StreamObserver` follows a stream and publishes whether what it carries is valid, emitting only the
changes of that validity rather than every value.

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

### Read a JSON object

```dart
final name = JsonUtility.getNotNullOnePrimaryElement<String>(
  json: json,
  key: "name",
  logger: _logger,
);

final delay = JsonUtility.getOneElement<Duration, int>(
  json: json,
  key: "delay",
  canBeUndefined: true,
  castValueFunc: DurationUtility.parseFromSeconds,
  logger: _logger,
);

if (!delay.isOk) {
  return null;
}
```

### Encode a number for a device

```dart
final raw = NumUtility.convertDoubleToUInt16(temperature, 2, logger: _logger);
if (raw == null) {
  return null;
}

final frame = ByteUtility.convertToLsbFirst(number: raw, bytesNb: 2, isSigned: false);
```

### Protect a critical section

```dart
final _lock = LockUtility();

Future<void> writeSettings(Settings settings) =>
    _lock.protectLock(() => _file.writeAsString(settings.toJson()));
```

### Wait for a status

```dart
final status = await WaitUtility.waitForStatus<ConnectionStatus>(
  isExpectedStatus: (status) => status == ConnectionStatus.connected,
  valueGetter: () => _client.status,
  statusEmitter: _client.statusStream,
  doAction: _client.connect,
  timeout: const Duration(seconds: 30),
);
```

### Watch a shared resource

```dart
final _watcher = OnReleaseWatcher(callback: _sensor.stop, thresholdDuration: const Duration(
  seconds: 5,
));

Future<Measure> measure() => _watcher.supervise(_sensor.read);
```

### Parse an enum from a value

```dart
enum FrameKind with MixinUniqueValueType<int> {
  request(1),
  answer(2);

  @override
  final int uniqueValue;

  const FrameKind(this.uniqueValue);

  static FrameKind? parseFromValue(int? value) =>
      MixinUniqueValueType.tryToParseFromUniqueValue(value: value, values: values);
}
```

## Testing

Every source file of the package has its test file, under the same path in `test`. The tests cover
the nominal use of each helper and, for every one of them, what it does with an empty input, a value
outside of its range, a type it does not support and a value it cannot parse, as well as the
warnings it writes when it is given a logger. The tests which involve time run under a fake clock,
so they never wait on a real delay.

```console
> flutter test
```
