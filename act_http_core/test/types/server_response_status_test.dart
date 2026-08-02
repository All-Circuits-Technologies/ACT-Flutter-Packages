// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_core/act_http_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ServerResponseStatus.nonGenericValues", () {
    test("only holds the statuses linked to a HTTP code", () {
      expect(
        ServerResponseStatus.nonGenericValues.every((status) => status.httpStatus != null),
        isTrue,
      );
    });

    test("leaves the generic statuses out", () {
      expect(
        ServerResponseStatus.nonGenericValues.contains(ServerResponseStatus.genericSuccess),
        isFalse,
      );
    });

    test("gives a distinct code to every status", () {
      final codes = ServerResponseStatus.nonGenericValues
          .map((status) => status.httpStatus)
          .toSet();

      expect(codes.length, ServerResponseStatus.nonGenericValues.length);
    });
  });

  group("ServerResponseStatus.isOk", () {
    test("says a success is ok", () {
      expect(ServerResponseStatus.ok.isOk, isTrue);
      expect(ServerResponseStatus.created.isOk, isTrue);
      expect(ServerResponseStatus.genericSuccess.isOk, isTrue);
    });

    test("says an error is not ok", () {
      expect(ServerResponseStatus.notFound.isOk, isFalse);
      expect(ServerResponseStatus.internalServerError.isOk, isFalse);
      expect(ServerResponseStatus.genericError.isOk, isFalse);
    });

    test("takes the answer of the generic status it is linked to", () {
      for (final status in ServerResponseStatus.nonGenericValues) {
        expect(status.isOk, status.linkedGeneric.isOk);
      }
    });
  });

  group("ServerResponseStatus.linkedGeneric", () {
    test("returns the family of a status linked to a HTTP code", () {
      expect(ServerResponseStatus.ok.linkedGeneric, ServerResponseStatus.genericSuccess);
      expect(ServerResponseStatus.notFound.linkedGeneric, ServerResponseStatus.genericClientError);
      expect(
        ServerResponseStatus.internalServerError.linkedGeneric,
        ServerResponseStatus.genericServerError,
      );
    });

    test("returns a generic status itself", () {
      expect(
        ServerResponseStatus.genericClientError.linkedGeneric,
        ServerResponseStatus.genericClientError,
      );
    });
  });

  group("ServerResponseStatus.parseFromHttpStatus", () {
    test("returns the status which carries the code", () {
      expect(ServerResponseStatus.parseFromHttpStatus(200), ServerResponseStatus.ok);
      expect(ServerResponseStatus.parseFromHttpStatus(404), ServerResponseStatus.notFound);
      expect(
        ServerResponseStatus.parseFromHttpStatus(500),
        ServerResponseStatus.internalServerError,
      );
    });

    test("falls back on the family of a code it does not name", () {
      expect(ServerResponseStatus.parseFromHttpStatus(202), ServerResponseStatus.genericSuccess);
      expect(
        ServerResponseStatus.parseFromHttpStatus(418),
        ServerResponseStatus.genericClientError,
      );
      expect(
        ServerResponseStatus.parseFromHttpStatus(503),
        ServerResponseStatus.genericServerError,
      );
    });

    test("only counts as successes the codes below the first redirection", () {
      // The success range stops at 300, which is the only redirection the enum names, so the other
      // redirections fall back on the generic error.
      expect(ServerResponseStatus.parseFromHttpStatus(299), ServerResponseStatus.genericSuccess);
      expect(ServerResponseStatus.parseFromHttpStatus(300), ServerResponseStatus.multipleChoices);
      expect(ServerResponseStatus.parseFromHttpStatus(301), ServerResponseStatus.genericError);
    });

    test("returns the generic error for a code outside of the known families", () {
      expect(ServerResponseStatus.parseFromHttpStatus(600), ServerResponseStatus.genericError);
      expect(ServerResponseStatus.parseFromHttpStatus(99), ServerResponseStatus.genericError);
      expect(ServerResponseStatus.parseFromHttpStatus(0), ServerResponseStatus.genericError);
    });

    test("reads back the code of every status which has one", () {
      for (final status in ServerResponseStatus.nonGenericValues) {
        expect(ServerResponseStatus.parseFromHttpStatus(status.httpStatus!), status);
      }
    });
  });
}
