import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/features/developer/console_controller.dart';
import 'package:htmlviewer/features/developer/console_model.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('add appends messages in order', () {
    final notifier = container.read(consoleProvider.notifier);
    notifier.add(ConsoleLevel.log, 'a');
    notifier.add(ConsoleLevel.warning, 'b');
    notifier.add(ConsoleLevel.error, 'c');

    final messages = container.read(consoleProvider);
    expect(messages.length, 3);
    expect(messages.map((m) => m.level).toList(),
        [ConsoleLevel.log, ConsoleLevel.warning, ConsoleLevel.error]);
  });

  test('errorCount counts only errors', () {
    final notifier = container.read(consoleProvider.notifier);
    notifier.add(ConsoleLevel.log, 'a');
    notifier.add(ConsoleLevel.error, 'b');
    notifier.add(ConsoleLevel.error, 'c');
    expect(notifier.errorCount, 2);
  });

  test('caps at 500 entries keeping the newest', () {
    final notifier = container.read(consoleProvider.notifier);
    for (var i = 0; i < 520; i++) {
      notifier.add(ConsoleLevel.log, 'm$i');
    }
    final messages = container.read(consoleProvider);
    expect(messages.length, 500);
    expect(messages.first.text, 'm20');
    expect(messages.last.text, 'm519');
  });

  test('clear empties the console', () {
    final notifier = container.read(consoleProvider.notifier);
    notifier.add(ConsoleLevel.log, 'a');
    notifier.clear();
    expect(container.read(consoleProvider), isEmpty);
  });

  group('addRaw parses bridge payloads', () {
    test('valid JSON with level and text', () {
      final notifier = container.read(consoleProvider.notifier);
      notifier
        ..addRaw('{"level":"error","text":"Uncaught ReferenceError: foo is not defined"}')
        ..addRaw('{"level":"warning","text":"Image failed to load"}')
        ..addRaw('{"level":"log","text":"hello"}');

      final messages = container.read(consoleProvider);
      expect(messages[0].level, ConsoleLevel.error);
      expect(messages[0].text, 'Uncaught ReferenceError: foo is not defined');
      expect(messages[1].level, ConsoleLevel.warning);
      expect(messages[2].level, ConsoleLevel.log);
    });

    test('malformed payload falls back to a log entry', () {
      final notifier = container.read(consoleProvider.notifier);
      notifier.addRaw('plain text without braces');
      final messages = container.read(consoleProvider);
      expect(messages.single.level, ConsoleLevel.log);
      expect(messages.single.text, 'plain text without braces');
    });

    test('JSON with extra fields still extracts level/text', () {
      final notifier = container.read(consoleProvider.notifier);
      notifier.addRaw('{"ts":123,"level":"warn","text":"x"}');
      final messages = container.read(consoleProvider);
      expect(messages.single.level, ConsoleLevel.warning);
      expect(messages.single.text, 'x');
    });

    test('escaped quotes and newlines are unescaped', () {
      final notifier = container.read(consoleProvider.notifier);
      notifier.addRaw(r'{"level":"error","text":"line1\nline \"2\""}');
      final messages = container.read(consoleProvider);
      expect(messages.single.text, 'line1\nline "2"');
    });
  });
}
