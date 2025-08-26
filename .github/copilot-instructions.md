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
  - [Package Structure (All 51 packages follow this pattern)](#package-structure-all-51-packages-follow-this-pattern)
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
./tool/pub_get_all.sh  # NEVER CANCEL: Takes 10-15 minutes for all 52 packages. Set timeout to 30+ minutes.
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
# NEVER CANCEL: Takes 15-25 minutes to analyze all 52 packages. Set timeout to 45+ minutes.
```

- Analyze a single package:

```bash
cd <package_name>
flutter pub upgrade  # Takes 30-60 seconds per package
flutter analyze --fatal-infos .  # Takes 10-30 seconds per package
```

- Generate GitHub Actions (after adding new packages):

```bash
dart pub global run mono_repo generate  # Takes 1-2 minutes
```

### Repository Management Commands

- Generate package list for README:

```bash
dart pub global run mono_repo readme --pad
```

- Create new package:

```bash
flutter create --template=package <your_package_name>
# Then manually add mono_pkg.yaml with analyze stage
# Then run:
dart pub global run mono_repo generate
```

## Validation Scenarios

### Critical Validation Steps

After making any changes to packages, ALWAYS run these validation steps:

1. **Single Package Validation**:

    ```bash
    cd <modified_package>
    flutter pub upgrade
    flutter analyze --fatal-infos .
    # Both commands must complete successfully
    ```

2. **Full Repository Validation** (before committing):

    ```bash
    # NEVER CANCEL: This is the same process that CI runs
    chmod +x ./tool/ci.sh  # Make script executable if needed
    PKGS="$(find . -name 'mono_pkg.yaml' | sed 's|./||; s|/mono_pkg.yaml||' | tr '\n' ' ')" \
    ./tool/ci.sh analyze
    # Expected time: 15-25 minutes for all packages. Set timeout to 45+ minutes.
    ```

3. **Markdown Validation**:

    ```bash
    # Check markdown formatting (runs in CI)
    markdownlint *.md  # If available, otherwise CI will catch issues
    ```

## Key Repository Structure

### Package Structure (All 51 packages follow this pattern)

```text
act_<package_name>/
├── lib/                    # Main source code
├── test/                   # Test files (mostly minimal)
├── pubspec.yaml            # Package definition with "sdk: flutter"
├── mono_pkg.yaml           # Mono repo configuration with "analyze" stage
├── README.md               # Package documentation
└── .metadata               # Flutter metadata
```

### Important Configuration Files

- `mono_repo.yaml` - Main monorepo configuration (defines analyze stage)
- `analysis_options.yaml` - Strict Flutter linting rules (very comprehensive)
- `.github/workflows/dart.yml` - Generated CI workflow (DO NOT EDIT MANUALLY)
- `tool/ci.sh` - Generated CI script (DO NOT EDIT MANUALLY)

### Generated Files (DO NOT EDIT)

- `.github/workflows/dart.yml` - Regenerated by `mono_repo generate`
- `tool/ci.sh` - Regenerated by `mono_repo generate`

## Common Operations

### Working with Packages

- All packages use `publish_to: none` (not published to pub.dev)
- All packages require Flutter SDK (`sdk: flutter`)
- All packages must pass `flutter analyze --fatal-infos .`
- Test files exist but are mostly empty (`void main() {}`)

### Integration with Projects

Projects consume these packages as git dependencies:

```yaml
# In consuming project's pubspec.yaml
act_abstract_manager:
  git:
    path: actlibs/act_abstract_manager
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
- `dart pub global run mono_repo generate`: 5+ minutes timeout
- Single package `flutter pub upgrade`: 2+ minutes timeout
- Single package `flutter analyze`: 2+ minutes timeout

### CI Pipeline Timing

- GitHub Actions workflow runs analysis on all 52 packages
- Expected CI time: 20-30 minutes total
- Each package: pub upgrade (30-60s) + analyze (10-30s)

## Error Prevention

### Before Committing Changes

Always run these commands in sequence:

```bash
# 1. Ensure Flutter is available
flutter --version

# 2. Validate your specific package(s)
cd <your_package>
flutter pub upgrade && flutter analyze --fatal-infos .

# 3. Generate updated GitHub Actions if you added/modified packages
dart pub global run mono_repo generate

# 4. Run full validation (same as CI)
cd /path/to/repo/root
chmod +x ./tool/ci.sh  # Make script executable if needed
PKGS="$(find . -name 'mono_pkg.yaml' | sed 's|./||; s|/mono_pkg.yaml||' | tr '\n' ' ')" \
./tool/ci.sh analyze
# NEVER CANCEL: Set timeout to 45+ minutes
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

- **Total packages**: 52 Flutter packages
- **Main CI operation**: Analysis only (no building/testing of applications)
- **Package types**: All are library packages, no applications
- **Dependencies**: Heavy use of Flutter ecosystem packages
