<!--
SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Licenses Manager <!-- omit from toc -->

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Presentation](#presentation)
- [Usage](#usage)

## Presentation

This package contains useful classes to manage the licenses of the app and its dependencies.

Flutter only provides a way to display the licenses of the dependencies of the app from LICENSE
files.
Because we use `reuse` to manage our files licenses, those licenses aren't loaded by Flutter.
Therefore, this package provides a way to load the licenses from the config and from the assets
folders, and to display them in the licenses page of the app.

## Usage

To add licenses from the ACT packages, your app or any other elements, such as a font. You can use
specific keys from the config file.

For instance:

```yaml
# The licenses configuration
licenses:
  # The extra elements and their licenses
  extraElements:
    ACT packages:
      - CC0-1.0
      - MIT
      - LicenseRef-ALLCircuits-ACT-1.1
      - LicenseRef-DartProjectAuthors
    MyApp:
      - Apache-2.0
      - LicenseRef-ALLCircuits-ACT-1.1
      - CC0-1.0
      - MIT
      - MyLicense
    Roboto:
      - OFL-1.1

  # The assets folders to look for licenses files
  assetsFolders:
    - LICENSES
    - actlibs/LICENSES

  # The license texts, the key is the license name, and the value is the license text
  texts:
    MyLicense: |
      This is my license text.
```
