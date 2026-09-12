import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_storage.dart';

/// Starter page inserted into a brand-new editor draft.
const editorStarterTemplate = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>我的第一个网页</title>
  <style>
    body {
      font-family: sans-serif;
      background: #101411;
      color: #e4e7e0;
      text-align: center;
      padding: 48px 16px;
    }
    h1 { color: #8ed468; }
    button {
      padding: 10px 22px;
      font-size: 16px;
      background: #6fbf4a;
      color: #ffffff;
      border: none;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <h1>你好，方块世界！</h1>
  <p>这是在 HTMLViewer 编辑器里手写的页面。</p>
  <button onclick="console.log('按钮被点击了！')">点我一下</button>
</body>
</html>
''';

/// Persists the handwritten HTML draft as a single string.
class EditorStorage {
  EditorStorage(this._prefs);

  static const _draftKey = 'htmlviewer.editor.draft';

  final SharedPreferences _prefs;

  /// Loads the draft; a never-saved editor starts with the starter template,
  /// while an explicitly emptied draft stays empty.
  String loadDraft() {
    final raw = _prefs.getString(_draftKey);
    if (raw == null) return editorStarterTemplate;
    return raw;
  }

  Future<void> saveDraft(String value) => _prefs.setString(_draftKey, value);
}

final editorStorageProvider = Provider<EditorStorage>(
  (ref) => EditorStorage(ref.watch(prefsProvider)),
);
