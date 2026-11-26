<!--
SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>

SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
-->

# Act Remote Storage Manager <!-- omit from toc -->

## Table of contents

- [Table of contents](#table-of-contents)
- [Presentation](#presentation)
- [Architecture](#architecture)
  - [The manager and its service](#the-manager-and-its-service)
  - [The cache](#the-cache)
  - [Listing the files](#listing-the-files)
  - [The HTTP service](#the-http-service)
- [How to use](#how-to-use)
  - [Installation](#installation)
  - [Write a storage service](#write-a-storage-service)
  - [Register the manager](#register-the-manager)
  - [Download a file](#download-a-file)
- [Configuration](#configuration)
- [Testing](#testing)

## Presentation

This package downloads the files an application keeps on a remote storage, and keeps a copy of them
on the device so that a file is downloaded once rather than every time it is displayed.

It talks to no storage in particular. Which storage an application uses, and how a file is named on
it, is the business of the service the application brings; this package only defines what such a
service has to answer and drives it. A generic service over HTTP is included, and other packages
bring the ones of a cloud provider.

## Architecture

### The manager and its service

`AbsRemoteStorageManager` is what an application registers, and `MixinStorageService` is what it
talks to. A file is named by a `fileId`, and what that identifier means is decided by the service:
a path, a key, a whole url.

```mermaid
flowchart LR
    app["Application"] --> manager["AbsRemoteStorageManager"]
    manager --> cache["CacheService"]
    manager --> service["MixinStorageService"]
    cache --> fileService["StorageHttpFileService"]
    fileService --> service
    service --> remote[("Remote storage")]
```

A service answers three questions: where a file can be downloaded from, the file itself, and the
files under a path. Every answer carries a `StorageRequestResult` alongside the value, so a caller
knows whether nothing came back because the file is missing, because it is not allowed to read it,
or because the device could not write it down.

### The cache

The cache is optional, and off unless the configuration turns it on. When it is on, the manager
reads a file through it, and the cache downloads it only when it does not have it or when its copy
has gone stale.

The cache does not know the remote storage: it downloads through `StorageHttpFileService`, which
asks the service of the application where the file is and then downloads from that address. A
service which needs headers, such as an authorization, exposes them and they are sent along.

Reading a file with the cache turned off, while asking for it, falls back on the storage and warns:
a file is returned either way, only slower.

Caching is done by [flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager), and the
images are cached at the size they are asked for as well as at their own.

### Listing the files

A storage answers a listing one page at a time, and `listFilesUntil` follows the pages so a caller
does not have to. It stops when the storage says there is no page left, when the caller says the
last page holds what it was looking for, or when the caller says the files gathered so far are
enough. An error on any page stops it, and nothing is returned rather than a partial listing.

### The HTTP service

`HttpStorageService` serves the files of a folder over HTTP. It has no listing, because the protocol
has none, and it refuses a file whose identifier would climb out of the folder it serves rather than
downloading whatever the identifier points at.

## How to use

### Installation

Add the package to the `dependencies` of your package:

```yaml
dependencies:
  act_remote_storage_manager:
    path: ../act_remote_storage_manager
```

### Write a storage service

A service is a manager of its own, which the application registers and the storage manager finds:

```dart
class MyStorageService extends AbsWithLifeCycle with MixinStorageService {
  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(String fileId) async {
    // Ask the storage where the file can be downloaded from
  }

  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    Directory? directory,
    OnProgressCallback? onProgress,
  }) async {
    // Download the file, reporting the progress if the caller asked for it
  }

  @override
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async {
    // Answer one page of the files under the path
  }
}
```

For a folder served over HTTP, the service already exists:

```dart
final service = HttpStorageService(
  httpRoot: Uri.parse("https://files.example/root"),
  headers: const {"Authorization": "Bearer aToken"},
);
```

### Register the manager

The configuration manager of the application has to carry the variables this package reads:

```dart
class AppConfigManager extends AbstractConfigManager with MixinStorageConfig {
  AppConfigManager({required super.logger});
}
```

```dart
class AppStorageManager extends AbsRemoteStorageManager<AppConfigManager> {
  @override
  Future<MixinStorageService> getStorageService() async => globalGetIt().get<MyStorageService>();
}

class AppStorageBuilder extends AbsRemoteStorageBuilder<AppStorageManager> {
  AppStorageBuilder() : super(AppStorageManager.new);

  @override
  Iterable<Type> dependsOn() => [...super.dependsOn(), AppConfigManager, MyStorageService];
}
```

The manager reads its service through `getStorageService`, so the manager which owns that service
has to be declared in `dependsOn`, otherwise it may not be built yet.

### Download a file

```dart
final manager = globalGetIt().get<AppStorageManager>();

final (:result, :file) = await manager.getFile("images/logo.png");
if (result == StorageRequestResult.success) {
  // The file is on the device
}

// Force a new download of a file which has changed on the storage
await manager.clearFileFromCache("images/logo.png");
```

Listing the files of a folder, following the pages until enough of them are known:

```dart
final (:result, :page) = await manager.listFilesUntil(
  "images",
  matchUntilWithAll: (items) => items.length >= 20,
);
```

## Configuration

| Key                                     | Default             | What it does                     |
| --------------------------------------- | ------------------- | -------------------------------- |
| `storage.cache.use`                     | `false`             | Turns the cache on               |
| `storage.cache.key`                     | `act_cache_manager` | Names the cache on the device    |
| `storage.cache.stalePeriod`             | `14`                | Days a cached file is kept for   |
| `storage.cache.numberOfObjectsCached`   | `100`               | Files the cache keeps at most    |
| `storage.pathSeparator`                 | `/`                 | Separator the storage names with |

## Testing

The tests drive the manager over a storage the test answers for, which covers the file it hands
over, the error it passes on, the cache which is asked for while the application uses none, and the
separator it reads from the configuration.

The following of the pages is covered on the pages which are gathered, on the token carried from
one call to the next, on the two conditions a caller may stop on, and on the error which stops it
and returns nothing rather than half of a listing.

The service over HTTP is covered on the addresses it builds, including the identifier which starts
with a separator and the one which would climb out of the folder it serves, and on the listing it
refuses. The file service of the cache is covered on the download it gives up on because the
storage cannot say where the file is.

The cache itself is not covered: it writes on the device, through a database and a folder a test has
no access to.

```console
> flutter test
```
