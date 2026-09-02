import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'console_model.dart';

/// Console entries of the current preview session.
///
/// Cleared whenever a new page starts loading (see ViewerPage), so entries
/// always belong to the currently viewed document.
final consoleProvider =
    NotifierProvider<ConsoleNotifier, List<ConsoleMessage>>(
        ConsoleNotifier.new);

class ConsoleNotifier extends Notifier<List<ConsoleMessage>> {
  /// Maximum retained entries; older ones are dropped like a scrollback
  /// buffer.
  static const maxEntries = 500;

  @override
  List<ConsoleMessage> build() => [];

  void add(ConsoleLevel level, String text) {
    final message = ConsoleMessage(
      level: level,
      text: text,
      time: DateTime.now(),
    );
    // Keep the newest entries: drop from the front when over the cap.
    final next = [...state, message];
    state = (next.length > maxEntries)
        ? next.sublist(next.length - maxEntries)
        : next;
  }

  /// Parses a message coming from the JavaScript bridge channel.
  ///
  /// Payload format: `{"level":"error","text":"..."}`; anything malformed is
  /// kept as a raw log line so no information is silently lost.
  void addRaw(String raw) {
    const quote = '"';
    var level = ConsoleLevel.log;
    var text = raw;

    if (raw.length > 2 && raw.startsWith('{') && raw.endsWith('}')) {
      // Lightweight extraction avoids depending on dart:convert hot path
      // while staying robust to extra fields.
      final levelMatch = RegExp(
        '"level"\\s*:\\s*"$quote?([a-z]+)"?',
      ).firstMatch(raw);
      final textMatch = RegExp(
        r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"',
      ).firstMatch(raw);
      if (levelMatch != null && textMatch != null) {
        switch (levelMatch.group(1)) {
          case 'warning':
          case 'warn':
            level = ConsoleLevel.warning;
          case 'error':
            level = ConsoleLevel.error;
          case 'log':
          default:
            level = ConsoleLevel.log;
        }
        text = textMatch
            .group(1)!
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\\', '\\');
      }
    }

    add(level, text);
  }

  void clear() => state = [];

  int get errorCount =>
      state.where((m) => m.level == ConsoleLevel.error).length;
}
