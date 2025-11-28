// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_storage_manager/src/models/storage_page.dart';
import 'package:act_remote_storage_manager/src/models/transfer_progress.dart';
import 'package:act_remote_storage_manager/src/services/storage/mixin_storage_service.dart';
import 'package:act_remote_storage_manager/src/types/storage_request_result.dart';
import 'package:act_remote_storage_manager/src/types/transfer_status.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// This service implements a generic HTTP/HTTPS storage service.
///
/// Note that there is no standardize way to list files of an HTTP folder, therefore this generic
/// HTTP service does not implement listFiles and returns a systematic error instead.
///
/// Also, this service does not support HTTP custom headers nor authentication (see getFile)
class HttpStorageService extends AbsWithLifeCycle with MixinStorageService {
  /// Logs category for the HTTP storage service
  static const _logsCategory = "storageHttp";

  /// HTTP root to work with.
  ///
  /// This must be a folder. Can be a simple server (such as "http://fqdn")
  /// or a more specialized URL (such as "http://fqdn:port/foo/folder/").
  final Uri _httpRoot;

  @override
  final Map<String, String>? headers;

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// Client used to download from HTTP.
  ///
  /// Using a client member increases chances to reuse same socket for subsequent requests.
  final HttpClient _httpClient;

  /// Class constructor
  HttpStorageService({
    required Uri httpRoot,
    this.headers,
  })  : _httpClient = HttpClient(),
        // Early ensure a final slash in our _httpRoot member so our getDownloadUrl is simpler
        _httpRoot = _ensureUriTrailingSlash(httpRoot),
        super();

  /// Initialize the service by creating the logs helper
  @override
  Future<void> initLifeCycle({LogsHelper? parentLogsHelper}) async {
    await super.initLifeCycle();
    if (parentLogsHelper == null) {
      _logsHelper = LogsHelper(
        logsManager: globalGetIt().get<LoggerManager>(),
        logsCategory: _logsCategory,
      );
    } else {
      _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);
    }
  }

  /// Get the download url of a file based on a [fileId].
  @override
  Future<({StorageRequestResult result, String? downloadUrl})> getDownloadUrl(
    String fileId,
  ) async {
    final fileUri = _getDownloadUri(fileId: fileId);

    if (fileUri == null) {
      return (
        result: StorageRequestResult.genericError,
        downloadUrl: null,
      );
    }

    return (
      result: StorageRequestResult.success,
      downloadUrl: fileUri.toString(),
    );
  }

  /// Download [fileId] file, in a local [directory] or in a default download directory.
  /// [onProgress] callback is not supported and ignored.
  // TODO(aloiseau): handle credentials and custom headers
  // Note(aloiseau): This method is not called when caching is enabled, which sounds weird
  //                 and may duplicate credentials/custom headers support code if any.
  @override
  Future<({StorageRequestResult result, File? file})> getFile(
    String fileId, {
    Directory? directory,
    OnProgressCallback? onProgress,
  }) async {
    // Compute URL to download
    final fileUri = _getDownloadUri(fileId: fileId);
    if (fileUri == null) {
      _logsHelper.e('Failed to compute download URL for $fileId');
      _handleEarlyFailureProgression(onProgress);
      return (result: StorageRequestResult.genericError, file: null);
    }

    // Prepare download destination
    try {
      // (getDownloadsDirectory may raise a MissingPlatformDirectoryException)
      directory ??= await MixinStorageService.getDownloadsDirectory();
    } on Exception catch (e) {
      _logsHelper.e('Failed to find a directory to download into: $e');
      _handleEarlyFailureProgression(onProgress);
      return (result: _parseException(e), file: null);
    }

    // TODO(aloiseau): Avoid file collision in local download area
    //    by either prepending a service-dedicated top folder into dlDirPath
    //    or by inserting a root or fileUri hash into dlDirPath or instead of fileId below
    final dlFilepath = path.join(directory.path, fileId);
    final dlDirPath = path.dirname(dlFilepath);

    // Create destination folder if needed
    try {
      // (directory creation may throw an exception)
      await Directory(dlDirPath).create(recursive: true);
    } on Exception catch (e) {
      _logsHelper.e('Failed to create download directory $directory: $e');
      _handleEarlyFailureProgression(onProgress);
      return (result: _parseException(e), file: null);
    }

    // Forge HTTP request
    final HttpClientResponse closeResp;
    try {
      // (getUrl and close may throw exceptions)
      final getReq = await _httpClient.getUrl(fileUri);

      // If the headers have been given we set them
      if (headers != null) {
        for (final header in headers!.entries) {
          getReq.headers.add(header.key, header.value);
        }
      }
      closeResp = await getReq.close();
    } on Exception catch (e) {
      _logsHelper.e('Failed to query URL $fileUri: $e');
      _handleEarlyFailureProgression(onProgress);
      return (result: _parseException(e), file: null);
    }

    final downloadResult = _parseHttpResponseCode(closeResp.statusCode);
    if (downloadResult != StorageRequestResult.success) {
      _handleEarlyFailureProgression(onProgress);
      return (result: StorageRequestResult.genericError, file: null);
    }

    // Download locally, by explicit chunks to handle optional progress feedback
    final dlFile = File(dlFilepath);
    final dlFileWriteStream = dlFile.openWrite();

    final contentLength = closeResp.contentLength;
    var downloadedBytes = 0;
    await for (final chunk in closeResp) {
      dlFileWriteStream.add(chunk);

      downloadedBytes += chunk.length;
      onProgress?.call(TransferProgress(
        bytesTransferred: downloadedBytes,
        totalBytes: contentLength, // Note: (-1) if unknown
        transferStatus: TransferStatus.inProgress,
      ));
    }

    // Free resources
    try {
      // If an error occurred while opening or writing the file,
      // then closing may throw an error
      await dlFileWriteStream.close();
      _logsHelper.d('File $fileId downloaded as $dlFilepath');
    } on Exception catch (e) {
      _logsHelper.e('Error while downloading file $fileId: $e');

      onProgress?.call(TransferProgress(
        bytesTransferred: downloadedBytes,
        totalBytes: contentLength, // Note: (-1) if unknown
        transferStatus: TransferStatus.failure,
      ));

      return (result: _parseException(e), file: null);
    }

    // Epilogue
    if (!dlFile.existsSync()) {
      _logsHelper.e("Downloaded file '${dlFile.path}' vanished");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, file: null);
    }

    onProgress?.call(TransferProgress(
      bytesTransferred: downloadedBytes,
      totalBytes: contentLength, // Note: (-1) if unknown
      transferStatus: TransferStatus.success,
    ));

    return (result: StorageRequestResult.success, file: dlFile);
  }

  /// HTTP have no standard listing feature. Always throw an UnsupportedError.
  // If needed one day, a http-server-specific listFiles may be implemented in a subclass
  // such as Nginx JSON file listing support, but this is out of scope here.
  @override
  Future<({StorageRequestResult result, StoragePage? page})> listFiles(
    String searchPath, {
    int? pageSize,
    String? nextToken,
    bool recursiveSearch = false,
  }) async =>
      throw UnsupportedError(
          "HTTP features no generic directory listing command");

  /// Tell if given [fileUri] (typically a download URI) appears safe or not
  ///
  /// It is especially considered unsafe if it would escape [_httpRoot] (and by the way likely escape
  /// locale download/cache area).
  bool _isFileUriSafe(Uri fileUri) =>
      // Basic for now
      path.isWithin(_httpRoot.path, fileUri.path);

  /// Get download Uri for given [fileId]
  Uri? _getDownloadUri({required String fileId}) {
    // Ensure fileId is later processed as a relative path to our root (which ends with a slash)
    var sanitizedRelativePath = fileId;

    while (sanitizedRelativePath.startsWith("/")) {
      sanitizedRelativePath = sanitizedRelativePath.substring(1);
    }

    final downloadUri = _httpRoot.resolve(sanitizedRelativePath);

    if (!_isFileUriSafe(downloadUri)) {
      _logsHelper.e("FileId $fileId appears wrong or unsafe, rejected");
      return null;
    }

    return downloadUri;
  }

  /// Announce an early download failure to [onProgress], if it is not null
  static void _handleEarlyFailureProgression(OnProgressCallback? onProgress) {
    onProgress?.call(const TransferProgress(
      // No bytes transferred
      bytesTransferred: 0,
      // Unknown source file size (we actually don't care for early failures)
      totalBytes: -1,
      transferStatus: TransferStatus.failure,
    ));
  }

  /// Return an Uri which forcibly finishes with a slash
  static Uri _ensureUriTrailingSlash(Uri uri) {
    if (!uri.path.endsWith('/')) {
      return uri.replace(path: '${uri.path}/');
    }
    return uri;
  }

  /// Convert a full download HTTP response code to a StorageRequestResult
  static StorageRequestResult _parseHttpResponseCode(int code) =>
      switch (code) {
        // We may want we use http_status or http_status_code package one day
        200 => StorageRequestResult.success,
        401 => StorageRequestResult.accessDenied,
        403 => StorageRequestResult.accessDenied,
        _ => StorageRequestResult.genericError,
      };

  /// Convert an exception to a StorageRequestResult
  static StorageRequestResult _parseException(Exception e) => switch (e) {
        HttpException _ => StorageRequestResult.ioError, // Closed by peer
        MissingPlatformDirectoryException _ => StorageRequestResult.ioError,
        HandshakeException _ => StorageRequestResult.ioError, // TLS issue
        SocketException _ =>
          StorageRequestResult.ioError, // Hostname resolution failed
        _ => StorageRequestResult.genericError,
      };
}
