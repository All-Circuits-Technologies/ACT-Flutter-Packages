<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT-Flutter-Packages - Agent Guidelines

> This is the entry point for AI coding agents working in this repository, following the
> [agents.md](https://agents.md/) convention. Claude Code reads it through the `CLAUDE.md` symlink.
> It links to the documentation instead of repeating it.

This repository is a mono repository of Dart and Flutter packages. They are not published on
pub.dev: applications use them through `path` dependencies.

## Coding standards

Before writing code, read
[`coding-standards.md`](https://github.com/All-Circuits-Technologies/ACT-Contributing/blob/master/software/coding-standards.md)
in ACT-Contributing, then the standards it lists for the files the change touches: the global
standards, then the Flutter standards.

Part of the existing code predates these standards: do not take it as a model. New code, and the
code a change touches, follow the standards.

## Tests

Write the tests as described in the [Tests](README.md#tests) section of the README: where they
live, how deep they go, how they are written, and which fakes are shared.

## Checks before pushing

- In each package the change touches, run `flutter analyze --fatal-infos .`, then `flutter test`
  when the package has a `test` folder.
- After a change of a `mono_pkg.yaml` file, run `tool/mono_repo_generate.sh` from the repository
  root and commit the files it generates.
- The CI lints the Markdown files with `markdownlint-cli2` and the configuration of
  [`.markdownlint.yaml`](.markdownlint.yaml): lines are up to 100 characters long.

## Licensing (REUSE)

The CI runs `reuse lint`:

- Add an SPDX header to each new file, in a comment the format of the file supports. When the
  format has no comment, add a sibling `<file>.license` file carrying the header.
- Reference only a license which has a text file in [`LICENSES/`](LICENSES/).

The full duties are in the
[`CONTRIBUTING.md`](https://github.com/All-Circuits-Technologies/ACT-Contributing/blob/master/CONTRIBUTING.md)
of ACT-Contributing.

## Contribution workflow

- Write everything in English: code, documentation, commit messages, branch names, issues and pull
  requests.
- Start each change from a GitHub issue of this repository.
- Name the branch `<issue number>-<slug>`, with the number of that GitHub issue, never a number
  from another issue tracker.
- Create no branch for a project or an application which uses the packages: a change made for one
  of them goes through its own issue, branch and pull request, like any other change.
- Open the pull request against `master`. It is merged after review.

## Public content

This repository is public. The code, the documentation, the issues, the pull requests and the
commit messages name no application or client which uses the packages, and link to no private
resource.
