// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What a request the server received carried.
class ReceivedRequest {
  /// The HTTP method of the request.
  final String method;

  /// The URL the request was sent to.
  final Uri url;

  /// The headers of the request, with their keys in lower case, as the server reads them.
  final Map<String, String> headers;

  /// The body of the request, as it travelled.
  final List<int> bodyBytes;

  /// Class constructor
  const ReceivedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.bodyBytes,
  });

  /// The body of the request, read as text.
  String get body => utf8.decode(bodyBytes);

  /// The content type the request announced, if it announced one.
  String? get contentType => headers[HttpHeaders.contentTypeHeader];
}

/// What the server answers to a request.
class ServerAnswer {
  /// The HTTP status of the answer.
  final int statusCode;

  /// The content type of the answer, if it has a body of a known type.
  ///
  /// A null content type is what a server which answers nothing sends, and it is what the client
  /// reads to know that there is no body to parse.
  final String? contentType;

  /// The body of the answer.
  final String body;

  /// Whether the server waits for the test to release it before answering.
  ///
  /// This is how a test keeps a request in flight: as long as the answer is held, the client is
  /// still waiting for it.
  final bool held;

  /// Class constructor
  const ServerAnswer({this.statusCode = 200, this.contentType, this.body = "", this.held = false});

  /// An answer which carries [json] as a JSON body.
  factory ServerAnswer.json(Object? json, {int statusCode = 200}) =>
      ServerAnswer(statusCode: statusCode, contentType: "application/json", body: jsonEncode(json));

  /// An answer which carries [text] as plain text.
  factory ServerAnswer.text(String text, {int statusCode = 200}) =>
      ServerAnswer(statusCode: statusCode, contentType: "text/plain", body: text);
}

/// A server on the loopback which answers what the test lined up.
///
/// The requester of this package opens its own client and reaches a real address, so the boundary
/// a test drives it through is a real server rather than a fake client.
class FakeServer {
  /// The server which answers the requests.
  final HttpServer _server;

  /// The answers the server sends, one per request, in order.
  ///
  /// Once the list is empty, every request is answered with [defaultAnswer].
  final List<ServerAnswer> answers = [];

  /// The requests the server received, in the order it received them.
  final List<ReceivedRequest> received = [];

  /// The answer sent once the lined up ones have all been sent.
  ServerAnswer defaultAnswer = const ServerAnswer();

  /// Completes when the test releases the answers it asked the server to hold.
  final Completer<void> _release = Completer<void>();

  /// Private constructor
  FakeServer._(this._server);

  /// The host the server answers on.
  String get host => _server.address.address;

  /// The port the machine gave to the server.
  int get port => _server.port;

  /// The number of requests the server received.
  int get requestsNb => received.length;

  /// Starts a server on a port the machine chooses.
  static Future<FakeServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fakeServer = FakeServer._(server);

    unawaited(fakeServer._serve());

    return fakeServer;
  }

  /// Lets the held answers go.
  void release() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }

  /// Releases what is held and closes the server.
  Future<void> close() async {
    release();

    return _server.close(force: true);
  }

  /// Answers the requests until the server is closed.
  ///
  /// A request which is held does not hold the ones which come after it, so that a test can have
  /// several requests in flight at the same time.
  Future<void> _serve() async {
    await for (final request in _server) {
      unawaited(_answerTo(request));
    }
  }

  /// Reads [request], records it and answers it.
  Future<void> _answerTo(HttpRequest request) async {
    final bodyBytes = <int>[];
    await for (final chunk in request) {
      bodyBytes.addAll(chunk);
    }

    received.add(
      ReceivedRequest(
        method: request.method,
        url: request.uri,
        headers: _headersOf(request),
        bodyBytes: bodyBytes,
      ),
    );

    final answer = answers.isEmpty ? defaultAnswer : answers.removeAt(0);

    if (answer.held) {
      await _release.future;
    }

    request.response.statusCode = answer.statusCode;

    if (answer.contentType != null) {
      request.response.headers.set(HttpHeaders.contentTypeHeader, answer.contentType!);
    }

    request.response.write(answer.body);

    // The client of a test which timed out is already gone when the answer is finally sent
    await request.response.close().catchError((_) {});
  }

  /// The headers of [request], with one value per key.
  static Map<String, String> _headersOf(HttpRequest request) {
    final headers = <String, String>{};
    request.headers.forEach((name, values) => headers[name] = values.join(", "));

    return headers;
  }
}
