import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> fromNative(String method) async {
    const codec = StandardMethodCodec();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          '$packageName/app',
          codec.encodeMethodCall(MethodCall(method)),
          (_) {},
        );
  }

  test('packagesChanged from Android reaches the app', () async {
    var calls = 0;
    App().onPackagesChanged = () => calls++;
    addTearDown(() => App().onPackagesChanged = null);

    await fromNative('packagesChanged');
    await fromNative('packagesChanged');

    expect(calls, 2);
  });

  test('without a listener it is ignored', () async {
    App().onPackagesChanged = null;
    await fromNative('packagesChanged');
  });
}
