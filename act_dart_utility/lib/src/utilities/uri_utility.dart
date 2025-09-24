// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Utility class to work with URIs.
sealed class UriUtility {
  /// Default path separator to build uri paths.
  static const pathSeparator = '/';

  /// This is the https scheme
  static const httpsScheme = "https";

  /// This is the http scheme
  static const httpScheme = "http";

  /// This is the wss scheme
  static const wssScheme = "wss";

  /// This is the ws scheme
  static const wsScheme = "ws";

  /// Constructs a path from the given segments and replaces any parameters in the path.
  ///
  /// The [segments] parameter is a required list of strings that represent the parts of the path.
  /// The [separator] parameter is an optional string that specifies the separator to use between
  /// segments.
  /// The default value for [separator] is [pathSeparator].
  /// The [parameters] parameter is an optional map of key-value pairs that will be replaced in
  /// the path.
  ///
  /// Returns a string representing the constructed path with parameters replaced.
  static String formatPathFromSegments({
    required List<String> segments,
    String separator = pathSeparator,
    Map<String, String> parameters = const {},
  }) {
    // Join the segments with the separator
    var path = segments.join(separator);

    // Replace the parameters in the path
    for (final param in parameters.entries) {
      path = path.replaceAll(param.key, param.value);
    }

    return path;
  }

  /// Format a relative url from the given path segments. The path segment shouldn't contain
  /// [pathSeparator] chars (except if it's really wanted).
  ///
  /// This method is useful when you want to replace parameters in the given [segments]. The method
  /// searches the keys of [parameters] and replace them by its values.
  ///
  /// The method joins the path segments with [pathSeparator] before replacing the parameters.
  static String formatRelativeUrlPathFromSegments({
    required List<String> segments,
    Map<String, String> parameters = const {},
  }) {
    final path = formatPathFromSegments(
      segments: segments,
      parameters: parameters,
    );

    return Uri.encodeFull(path);
  }

  /// Create a new [Uri] object based on the [reference] given, and append the [segmentsToAppend] to
  /// the pathSegments of [reference].
  static Uri appendPathSegmentsToUri({
    required Uri reference,
    required List<String> segmentsToAppend,
  }) {
    final tmpSegments = List<String>.from(reference.pathSegments);
    tmpSegments.addAll(segmentsToAppend);

    return Uri(
      scheme: reference.scheme,
      userInfo: reference.userInfo,
      host: reference.host,
      port: reference.port,
      pathSegments: tmpSegments,
      queryParameters: reference.queryParametersAll,
      fragment: reference.fragment,
    );
  }

  /// The method test if the uri scheme is equals to [httpsScheme]
  static bool isHttpsUri(Uri uri) => uri.isScheme(httpsScheme);
}
