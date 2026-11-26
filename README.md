<!--
SPDX-FileCopyrightText: 2023, 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ActFlutterPackages  <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [mono\_repo](#mono_repo)
- [Packages](#packages)
- [How to use the packages in your project](#how-to-use-the-packages-in-your-project)
- [Tests](#tests)
  - [How to run the tests](#how-to-run-the-tests)
  - [Where the tests live](#where-the-tests-live)
  - [How deep the tests go](#how-deep-the-tests-go)
  - [How the tests are written](#how-the-tests-are-written)
  - [Test tooling](#test-tooling)
  - [Lint and continuous integration](#lint-and-continuous-integration)
- [Add a new package](#add-a-new-package)
- [Update the GitHub Actions Flutter version](#update-the-github-actions-flutter-version)

## Presentation

Shared flutter packages for all the Flutter projects.

## mono_repo

[mono_repo](https://github.com/google/mono_repo.dart) is used to manage multiple flutter packages
within a single repository.

We are using it to generate github actions and the packages list.

To install it globally, you have to call:

```console
> dart pub global activate mono_repo
```

## Packages

The packages are in the [`flutter/`](flutter/README.md) folder, whose README lists them.

To generate the rows of the table, you can call:

```console
> dart pub global run mono_repo readme --pad
```

This prints a markdown table of all the packages: copy each row to the README of the folder of its
package, with the link relative to that README, each time a package is added or removed.

## How to use the packages in your project

Add this repository as a git submodule of the project, by default in an `actlibs/` folder at its
root, and reference each package by its local path in `pubspec.yaml`:

```yaml
act_life_cycle:
  path: actlibs/flutter/act_life_cycle
```

A fresh clone of the project fetches the submodule with `git submodule update --init`.

The submodule points at `master`. A change a project needs gets its own issue here, independent of
the project; while that change is under review, the submodule of the project may point at its
branch, then returns to `master` once it is merged.

## Tests

### How to run the tests

Inside a package:

```console
> flutter test
```

For the whole repository:

```console
> tool/test_all.sh
```

The script skips the packages which have no `test` folder and prints the list of the packages
which failed.

### Where the tests live

The `test` folder of a package mirrors its `lib/src` folder: a source file `lib/src/a/b.dart` is
tested by `test/a/b_test.dart`.

What the tests of a package cover, and anything they deliberately leave out, is written in the
`Testing` section of the README of that package.

### How deep the tests go

The depth of the tests follows what the package is made of, so all packages are not covered the
same way:

- A package which holds pure logic (models, parsing, state, timers, extensions) is covered
  exhaustively, edge cases and error paths included.
- A manager which wraps a native plugin, a socket or a server is tested through the boundary it
  already defines: a fake takes the place of the plugin, and the tests cover the life cycle, the
  state machine, the parsing, the retries and the error handling. When a class cannot be reached
  without reshaping it, it is tested through an existing interface and its README says so. No
  abstraction is added to the sources for the sole purpose of making a test possible.
- A thin wrapper or a purely graphical package gets a smoke test or widget tests, and the effort
  goes to its README instead.

A package which ships no Dart code at all has no `test` folder, and therefore no `test` stage.

### How the tests are written

- One `group` per class or per public method, named after it.
- One `test` per behaviour, described in English and in the third person, for instance
  `returns null when the key is missing`.
- Arrange, act, assert, in this order and without any section comment.
- The test files carry the same SPDX header as the source files.

### Test tooling

- [`act_test_utility`](flutter/act_test_utility/) holds the fakes shared by several packages. It is added
  as a `dev_dependency` by the packages which use it, including the ones it depends on: pub
  resolves such a cycle between packages linked by a path. A package which defines a faked
  interface still keeps its own fake of it, in its `test` folder, and hides the shared name when
  it imports the shared fakes.
- [`mocktail`](https://pub.dev/packages/mocktail) is the mocking library. It needs no code
  generation, so there is no generated file to maintain. It is added as a `dev_dependency` only in
  the packages which need it.
- `fake_async`, which comes with `flutter_test`, is used for everything which depends on timers or
  delays. A test must never wait on a real delay.

### Lint and continuous integration

The analysis covers the test code too, so `flutter analyze --fatal-infos .` has to pass on the
`test` folder as well as on `lib`. The only rule which does not apply outside of `lib` is
`public_member_api_docs`.

The tests of a package are run by the CI once the package declares the `test` stage in its
`mono_pkg.yaml`:

```yaml
stages:
  - analyze:
      - group:
          - analyze: --fatal-infos .
  - test:
      - group:
          - test
```

The stage is only declared once the package actually has tests, because `flutter test` fails when
the `test` folder doesn't exist. A package whose tests need a browser asks for one in the same
place, with `test: --platform chrome`; it then gets its own job, because only the packages sharing
the very same command are grouped together.

`mono_repo.yaml` merges the `analyze` and `test` stages, so the whole repository is analysed in one
job and tested in another, instead of one job per package. This keeps a single `flutter pub upgrade`
per package, which is what a job per package would pay for, and the whole run takes about twenty
minutes.

As for any change made to a `mono_pkg.yaml` file, the CI configuration has to be regenerated and
committed:

```console
> tool/mono_repo_generate.sh
```

## Add a new package

To add a new package to actlibs, in the `flutter/` folder of `actlibs` you can call:

```console
> flutter create --template=package <your_package_name>
```

Then, in the `pubspec.yaml` you will have to set:

```yaml
publish_to: none
```

You will need to create a `mono_pkg.yaml` file with at least the stage: `analyze`, and to
add the package to the table of the README of its folder.

Then, you will have to call the next command to regenerate the GitHub Actions configuration
(this also re-applies the flutter-version patch):

```console
> tool/mono_repo_generate.sh
```

## Update the GitHub Actions Flutter version

`mono_repo` does not support a global Flutter version, so the version is set in each
`mono_pkg.yaml` file and persisted in `tool/.flutter_version`. Use the script:

```console
> tool/mono_repo_generate.sh --flutter-version <version>
```

Where `<version>` is the Flutter version to target, for example `3.41.9`. It may also be a
channel, for example `stable` or `beta`.

This command updates all `mono_pkg.yaml` files, saves the version to `tool/.flutter_version`,
and regenerates the CI configuration with the appropriate workflow patch.
