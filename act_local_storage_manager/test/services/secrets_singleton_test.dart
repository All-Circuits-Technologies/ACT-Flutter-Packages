// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecretsSingleton secrets;

  setUp(() {
    FakeGlobalManager.install();
    FlutterSecureStorage.setMockInitialValues({});
    secrets = SecretsSingleton.createInstance();
  });

  group("SecretsSingleton.createInstance", () {
    test("returns the same instance every time", () {
      expect(SecretsSingleton.createInstance(), same(secrets));
    });

    test("is the instance the items reach", () {
      expect(SecretsSingleton.instance, same(secrets));
    });
  });

  group("SecretsSingleton.store", () {
    test("keeps a boolean", () async {
      await secrets.store<bool>(key: "aKey", value: true);

      expect(await secrets.load<bool>(key: "aKey"), isTrue);
    });

    test("keeps an integer", () async {
      await secrets.store<int>(key: "aKey", value: 42);

      expect(await secrets.load<int>(key: "aKey"), 42);
    });

    test("keeps a double", () async {
      await secrets.store<double>(key: "aKey", value: 4.2);

      expect(await secrets.load<double>(key: "aKey"), 4.2);
    });

    test("keeps a string", () async {
      await secrets.store<String>(key: "aKey", value: "a value");

      expect(await secrets.load<String>(key: "aKey"), "a value");
    });

    test("returns true once the secret is kept", () async {
      expect(await secrets.store<String>(key: "aKey", value: "a value"), isTrue);
    });

    test("forgets the secret when it is given none", () async {
      await secrets.store<String>(key: "aKey", value: "a value");

      await secrets.store<String>(key: "aKey", value: null);

      expect(await secrets.load<String>(key: "aKey"), isNull);
    });

    test("replaces the secret which was kept under the same key", () async {
      await secrets.store<String>(key: "aKey", value: "a value");

      await secrets.store<String>(key: "aKey", value: "another value");

      expect(await secrets.load<String>(key: "aKey"), "another value");
    });

    test("refuses a type it cannot keep", () async {
      expect(
        () => secrets.store<Duration>(key: "aKey", value: const Duration(seconds: 1)),
        throwsA(isA<ActUnsupportedTypeError<Duration>>()),
      );
    });
  });

  group("SecretsSingleton.load", () {
    test("returns null for a key which was never stored", () async {
      expect(await secrets.load<String>(key: "aKey"), isNull);
    });

    test("returns null when the secret cannot be read as the type asked for", () async {
      await secrets.store<String>(key: "aKey", value: "a value");

      expect(await secrets.load<int>(key: "aKey"), isNull);
    });
  });

  group("SecretsSingleton.delete", () {
    test("forgets the secret of the key given", () async {
      await secrets.store<String>(key: "aKey", value: "a value");

      await secrets.delete(key: "aKey");

      expect(await secrets.load<String>(key: "aKey"), isNull);
    });
  });

  group("SecretsSingleton.deleteAll", () {
    test("forgets every secret which was kept", () async {
      await secrets.store<String>(key: "aKey", value: "a value");
      await secrets.store<int>(key: "anotherKey", value: 42);

      await secrets.deleteAll();

      expect(await secrets.load<String>(key: "aKey"), isNull);
      expect(await secrets.load<int>(key: "anotherKey"), isNull);
    });
  });
}
