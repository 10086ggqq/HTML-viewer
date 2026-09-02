/// Severity of a console entry.
enum ConsoleLevel { log, warning, error }

/// A single console entry captured from the preview WebView.
class ConsoleMessage {
  const ConsoleMessage({
    required this.level,
    required this.text,
    required this.time,
  });

  final ConsoleLevel level;
  final String text;
  final DateTime time;

  ConsoleMessage copyWith({String? text}) => ConsoleMessage(
        level: level,
        text: text ?? this.text,
        time: time,
      );
}
