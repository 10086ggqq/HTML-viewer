import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/core/services/zip_service.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('hv_zip_test');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  String normalize(String path) => path.replaceAll('\\', '/');

  String joinPath(String relative) => '${normalize(temp.path)}/$relative';

  File write(String path) {
    final f = File(joinPath(path));
    f.createSync(recursive: true);
    f.writeAsStringSync('<html></html>');
    return f;
  }

  test('prefers root index.html', () {
    write('index.html');
    write('about.html');
    write('deep/index.html');

    final entry = findEntryPoint(temp);
    expect(entry, isNotNull);
    expect(normalize(entry!.path), joinPath('index.html'));
  });

  test('falls back to shallowest nested index.html', () {
    final nested = write('site/index.html');
    write('site/deep/other.html');

    final entry = findEntryPoint(temp);
    expect(normalize(entry!.path), normalize(nested.path));
  });

  test('falls back to shallowest any html when no index exists', () {
    write('a/b/page.html');
    write('zzz.html');

    final entry = findEntryPoint(temp);
    expect(normalize(entry!.path), joinPath('zzz.html'));
  });

  test('returns null when no html at all', () {
    write('assets/logo.png');
    expect(findEntryPoint(temp), isNull);
  });
}
