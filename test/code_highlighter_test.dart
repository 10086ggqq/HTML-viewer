import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/features/source/code_highlighter.dart';

void main() {
  const highlighter = CodeHighlighter();

  test('splits highlighted HTML into lines', () {
    const source = '<html>\n  <body>\n    <p class="a">Hi</p>\n  </body>\n</html>';
    final lines = highlighter.highlight(source, 'html');

    expect(lines.length, 5);
    // Line 1 is just '<html>'.
    final line1 = lines[0].map((t) => t.text).join();
    expect(line1, '<html>');
    // Tag names carry the HTML orange color.
    final nameToken = lines[0].firstWhere(
      (t) => t.text.trim() == 'html' && t.text != '<html>',
      orElse: () => lines[0].first,
    );
    expect(nameToken.color, const Color(0xFFE8642B));
  });

  test('handles multi-line comment spanning lines', () {
    const source = '/* a\nb */\n.x { color: red; }';
    final lines = highlighter.highlight(source, 'css');
    expect(lines.length, 3);
    // The comment's second line keeps the comment color.
    final commentToken = lines[1].first;
    expect(commentToken.color, const Color(0xFF6E7A6A));
    expect(commentToken.text, 'b */');
  });

  test('plain text for unknown language', () {
    final lines = highlighter.highlight('a\nb', null);
    expect(lines.length, 2);
    expect(lines[0].single.color, CodePalette.plain);
  });

  test('falls back to plain tokens for huge content', () {
    final huge = 'x' * (CodeHighlighter.maxHighlightedChars + 1);
    final lines = highlighter.highlight(huge, 'html');
    expect(lines.length, 1);
    expect(lines[0].single.color, CodePalette.plain);
  });

  test('languageFor maps extensions', () {
    expect(highlighter.languageFor('html'), 'html');
    expect(highlighter.languageFor('htm'), 'html');
    expect(highlighter.languageFor('css'), 'css');
    expect(highlighter.languageFor('js'), 'javascript');
    expect(highlighter.languageFor('txt'), isNull);
  });

  test('windows line endings handled by caller normalization', () {
    // highlight() itself only splits on \n; callers normalize \r\n first.
    const source = 'a\r\nb';
    final lines = highlighter.highlight(source, null);
    expect(lines.length, 2);
    expect(lines[0].single.text, 'a\r');
  });
}
