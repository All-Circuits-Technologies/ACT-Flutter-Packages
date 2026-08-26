// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_qr_code/act_qr_code.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../fakes/fake_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLogger logger;
  late FakePermissions permissions;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
    permissions = FakePermissions();
  });

  tearDown(FakePermissions.stop);

  group("QrCodeBloc", () {
    test("starts without knowing the permission and without any code", () {
      permissions.serve();

      expect(QrCodeBloc().state, const QrCodeState.init());
    });

    test("reports the permission which is already granted", () async {
      permissions
        ..status = PermissionStatus.granted
        ..serve();

      final bloc = QrCodeBloc();

      await expectLater(
        bloc.stream,
        emits(isA<QrCodeState>().having((s) => s.permStatus, "permStatus", PermissionStatus.granted)),
      );
    });

    test("asks for a permission which has not been granted yet", () async {
      permissions
        ..status = PermissionStatus.denied
        ..statusAfterRequest = PermissionStatus.granted
        ..serve();

      final bloc = QrCodeBloc();

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QrCodeState>().having((s) => s.permStatus, "permStatus", PermissionStatus.denied),
          isA<QrCodeState>().having((s) => s.permStatus, "permStatus", PermissionStatus.granted),
        ]),
      );
      expect(permissions.requested, [Permission.camera.value]);
    });

    test("reports the refusal of a permission it asked for", () async {
      permissions
        ..status = PermissionStatus.denied
        ..statusAfterRequest = PermissionStatus.denied
        ..serve();

      final bloc = QrCodeBloc();
      await bloc.stream.first;

      // The refusal is the state the bloc is already in, so it reports it once
      expect(bloc.state.permStatus, PermissionStatus.denied);
      expect(permissions.requested, [Permission.camera.value]);
    });

    test("does not ask again for a permission which was permanently denied", () async {
      permissions
        ..status = PermissionStatus.permanentlyDenied
        ..serve();

      final bloc = QrCodeBloc();

      await expectLater(
        bloc.stream,
        emits(isA<QrCodeState>().having((s) => s.permStatus, "permStatus", PermissionStatus.permanentlyDenied)),
      );
      expect(permissions.requested, isEmpty);
    });

    test("warns about the permission which was permanently denied", () async {
      permissions
        ..status = PermissionStatus.permanentlyDenied
        ..serve();

      final bloc = QrCodeBloc();
      await bloc.stream.first;

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("reports a code which has been found", () async {
      permissions
        ..status = PermissionStatus.granted
        ..serve();
      final bloc = QrCodeBloc();
      await bloc.stream.first;

      bloc.add(const QrCodeFoundEvent(found: true));

      await expectLater(
        bloc.stream,
        emits(isA<QrCodeState>().having((s) => s.found, "found", isTrue)),
      );
    });

    test("keeps the permission it knows when a code is found", () async {
      permissions
        ..status = PermissionStatus.granted
        ..serve();
      final bloc = QrCodeBloc();
      await bloc.stream.first;

      bloc.add(const QrCodeFoundEvent(found: true));

      await expectLater(
        bloc.stream,
        emits(isA<QrCodeState>().having((s) => s.permStatus, "permStatus", PermissionStatus.granted)),
      );
    });
  });
}
