import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/app/app.dart';
import 'package:htmlviewer/storage/settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home renders with Minecraft-style empty states',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const HtmlViewerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HTMLViewer'), findsOneWidget);
    expect(find.text('还没有世界。'), findsOneWidget);
    expect(find.text('最近打开'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const HtmlViewerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(find.text('箱子还是空的。'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('像素字体'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('允许网页运行 JavaScript'),
      120,
    );
    expect(find.text('JavaScript'), findsOneWidget);
    expect(find.text('允许网页运行 JavaScript'), findsOneWidget);
  });

  testWidgets('Editor tab opens with the starter template', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const HtmlViewerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('编写'));
    await tester.pumpAndSettle();

    expect(find.text('手写 HTML'), findsOneWidget);
    expect(find.byIcon(Icons.file_open), findsOneWidget);
    expect(find.textContaining('你好，方块世界'), findsOneWidget);
  });
}
