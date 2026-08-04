<!--
SPDX-FileCopyrightText: 2025 Théo Magne <theo.magne@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# ACT Flutter Packages Monorepo <!-- omit from toc -->

This file contains instructions for github copilot agent, not meant to be used by a human but it may
contains useful information for understanding the repository structure and workflows.

Always follow these instructions first and fallback to search or bash commands only when you
encounter unexpected information that does not match the info here.

## Table of content <!-- omit from toc -->

- [Working Effectively](#working-effectively)
  - [Essential Setup Commands](#essential-setup-commands)
  - [Core Analysis and Validation Commands](#core-analysis-and-validation-commands)
  - [Repository Management Commands](#repository-management-commands)
- [Validation Scenarios](#validation-scenarios)
  - [Critical Validation Steps](#critical-validation-steps)
- [Key Repository Structure](#key-repository-structure)
  - [Package Structure (All 68 packages follow this pattern)](#package-structure-all-68-packages-follow-this-pattern)
  - [Important Configuration Files](#important-configuration-files)
  - [Generated Files (DO NOT EDIT)](#generated-files-do-not-edit)
- [Common Operations](#common-operations)
  - [Working with Packages](#working-with-packages)
  - [Integration with Projects](#integration-with-projects)
  - [Branch Strategy](#branch-strategy)
- [Timing Expectations and Timeout Values](#timing-expectations-and-timeout-values)
  - [Command Timeouts (CRITICAL - NEVER CANCEL)](#command-timeouts-critical---never-cancel)
  - [CI Pipeline Timing](#ci-pipeline-timing)
- [Error Prevention](#error-prevention)
  - [Before Committing Changes](#before-committing-changes)
  - [Common Issues and Solutions](#common-issues-and-solutions)
- [Repository Statistics](#repository-statistics)

## Working Effectively

### Essential Setup Commands

- Install Flutter SDK (required for all operations):

```bash
# Method 1: Clone Flutter (most reliable when network allows)
cd /tmp && git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
export PATH=/tmp/flutter/bin:$PATH
# Add to your shell profile:
echo 'export PATH=/tmp/flutter/bin:$PATH' >> ~/.bashrc

# Method 2: Use package manager (if snap is available)
sudo snap install flutter --classic

# Verify installation - CRITICAL: Network restrictions may cause failures
flutter doctor  # NEVER CANCEL: Takes 3-5 minutes on first run. Set timeout to 10+ minutes.
# If "dart-sdk-linux-x64.zip corrupt" error occurs, network restrictions are blocking downloads
```

- Install mono_repo (monorepo management tool):

```bash
dart pub global activate mono_repo
```

- Set up package dependencies:

```bash
# Use the provided script to install all package dependencies
./tool/pub_get_all.sh  # NEVER CANCEL: Takes 10-15 minutes for all 68 packages. Set timeout to 30+ minutes.
# View script help:
./tool/pub_get_all.sh --help  # This works without Flutter
```

### Core Analysis and Validation Commands

- Analyze all packages (primary CI operation):

```bash
# Using the generated CI script - get all packages dynamically
chmod +x ./tool/ci.sh  # Make script executable if needed
PKGS="$(find . -name 'mono_pkg.yaml' | sed 's|./||; s|/mono_pkg.yaml||' | tr '\n' ' ')" \
./tool/ci.sh analyze
# NEVER CANCEL: Takes 15-25 minutes to analyze all 68 packages. Set timeout to 45+ minutes.
```

- Analyze a single package:

```bash
cd <package_name>
flutter pub upgrade  # Takes 30-60 seconds per package
flutter analyze --fatal-infos .  # Takes 10-30 seconds per package
```

- Test all packages (second CI operation):

```bash
# The script skips the packages which have no test folder and lists the failing ones
./tool/test_all.sh  # NEVER CANCEL: Takes 30-45 minutes. Set timeout to 60+ minutes.
# View script help:
./tool/test_all.sh --help  # This works without Flutter
```

- Test a single package:

```bash
cd <package_name>
flutter test  # Takes 10-60 seconds per package
```

- Generate GitHub Actions (after adding new packages or editing a `mono_pkg.yaml`):

```bash
# Do not call "mono_repo generate" directly: this script also applies the patches
# the generated workflow needs (flutter-version, self-validate step)
bash tool/mono_repo_generate.sh  # Takes 1-2 minutes
```

### Repository Management Commands

- Generate package list for README:

```bash
dart pub global run mono_repo readme --pad
```

- Create new package:

```bash
flutter create --template=package <your_package_name>
# Then manually add mono_pkg.yaml with the analyze stage, and the test stage once it has tests
# Then run:
bash tool/mono_repo_generate.sh
```

## Validation Scenarios

### Critical Validation Steps

After making any changes to packages, ALWAYS run these validation steps:

1. **Single Package Validation**:

    ```bash
    cd <modified_package>
    flutter pub upgrade
    flutter analyze --fatal-infos .
    flutter test  # Skip this one only when the package has no test folder
    # All the commands must complete successfully
    ```

2. **Full Repository Validation** (before committing):

    ```bash
    # NEVER CANCEL: This is the same process that CI runs
    chmod +x ./tool/ci.sh  # Make script executable if needed
    PKGS="$(find . -name 'mono_pkg.yaml' | sed 's|./||; s|/mono_pkg.yaml||' | tr '\n' ' ')" \
    ./tool/ci.sh analyze
    # Expected time: 15-25 minutes for all packages. Set timeout to 45+ minutes.
    ./tool/test_all.sh
    # Expected time: 30-45 minutes for all packages. Set timeout to 60+ minutes.
    ```

3. **Markdown Validation**:

    ```bash
    # Check markdown formatting (runs in CI)
    markdownlint *.md  # If available, otherwise CI will catch issues
    ```

## Key Repository Structure

### Package Structure (All 68 packages follow this pattern)

```text
act_<package_name>/
├── lib/                    # Main source code
├── test/                   # Unit tests, mirroring the lib/src tree
├── pubspec.yaml            # Package definition with "sdk: flutter"
├── mono_pkg.yaml           # Mono repo configuration with the "analyze" and "test" stages
├── README.md               # Package documentation
└── .metadata               # Flutter metadata
```

### Important Configuration Files

- `mono_repo.yaml` - Main monorepo configuration (merges the analyze and test stages)
- `analysis_options.yaml` - Strict Flutter linting rules (very comprehensive)
- `.github/workflows/dart.yml` - Generated CI workflow (DO NOT EDIT MANUALLY)
- `tool/ci.sh` - Generated CI script (DO NOT EDIT MANUALLY)

### Generated Files (DO NOT EDIT)

- `.github/workflows/dart.yml` - Regenerated by `tool/mono_repo_generate.sh`
- `tool/ci.sh` - Regenerated by `tool/mono_repo_generate.sh`

## Common Operations

### Working with Packages

- All packages use `publish_to: none` (not published to pub.dev)
- All packages require Flutter SDK (`sdk: flutter`)
- All packages must pass `flutter analyze --fatal-infos .`, test code included
- Every package which ships Dart code has unit tests and must pass `flutter test`
- The test conventions (layout, naming, shared fakes, mocking library) are described in the
  "Tests" section of the root `README.md`

### Integration with Projects

Projects consume these packages as git dependencies:

```yaml
# In consuming project's pubspec.yaml
act_life_cycle:
  git:
    path: actlibs/act_life_cycle
```

### Branch Strategy

- Create project-specific branches for consuming projects
- Regularly merge project branches back to master via merge requests
- Master branch should always pass all CI checks

## Timing Expectations and Timeout Values

### Command Timeouts (CRITICAL - NEVER CANCEL)

- `flutter doctor` (first run): 10+ minutes timeout
- `./tool/pub_get_all.sh`: 30+ minutes timeout
- Full repository analysis: 45+ minutes timeout
- `./tool/test_all.sh`: 60+ minutes timeout
- `bash tool/mono_repo_generate.sh`: 5+ minutes timeout
- Single package `flutter pub upgrade`: 2+ minutes timeout
- Single package `flutter analyze`: 2+ minutes timeout
- Single package `flutter test`: 5+ minutes timeout

### CI Pipeline Timing

- GitHub Actions workflow runs the analysis on all 68 packages in one job, and the tests in
  another one
- Expected CI time: about 6 minutes for the analysis job, about 15 for the test one
- Each package: pub upgrade (30-60s) + analyze (10-30s) + test (10-60s)

## Error Prevention

### Before Committing Changes

Always run these commands in sequence:

```bash
# 1. Ensure Flutter is available
flutter --version

# 2. Validate your specific package(s)
cd <your_package>
flutter pub upgrade && flutter analyze --fatal-infos . && flutter test

# 3. Generate updated GitHub Actions if you added/modified packages or their mono_pkg.yaml
cd /path/to/repo/root
bash tool/mono_repo_generate.sh

# 4. Run full validation (same as CI)
chmod +x ./tool/ci.sh  # Make script executable if needed
PKGS="$(find . -name 'mono_pkg.yaml' | sed 's|./||; s|/mono_pkg.yaml||' | tr '\n' ' ')" \
./tool/ci.sh analyze
./tool/test_all.sh
# NEVER CANCEL: Set timeout to 45+ minutes for each of them
```

### Common Issues and Solutions

- **Flutter not found**: Ensure Flutter is in PATH and `flutter doctor` passes
- **Package analysis fails**: Check `analysis_options.yaml` for strict linting rules
- **CI generation fails**: Ensure each package has valid `mono_pkg.yaml`
- **Network timeouts**: Use longer timeouts for all package operations
- **Script permission denied**: Run `chmod +x ./tool/ci.sh` to make CI script executable
- **Flutter download fails**:
  - Network restrictions may prevent downloading Dart SDK components
  - Try alternative installation methods (snap, apt, or pre-downloaded archives)
  - In restricted environments, request network access to: storage.googleapis.com
- **"dart-sdk-linux-x64.zip corrupt" error**: Network/firewall blocking Flutter SDK downloads

## Repository Statistics

- **Total packages**: 68 Flutter packages
- **Main CI operations**: Analysis and unit tests (no building of applications)
- **Package types**: All are library packages, no applications
- **Dependencies**: Heavy use of Flutter ecosystem packages
