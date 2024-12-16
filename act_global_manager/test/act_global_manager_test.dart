import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_two_manager.dart';
import 'test_global_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfoMock();

  test('Test registering managers with different levels', () async {
    await TestGlobalManager.staticCreate().allReadyBeforeView();
    expect(
      GlobalGetIt().get<LevelTwoManager>().magicNumber,
      LevelTwoManager.cstMagicNumber,
    );
  });
}

void packageInfoMock() {
  const MethodChannel('plugins.flutter.io/package_info')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{
        'appName': 'ABC',
        'packageName': 'A.B.C',
        'version': '1.0.0',
        'buildNumber': ''
      };
    }
    return null;
  });
}
