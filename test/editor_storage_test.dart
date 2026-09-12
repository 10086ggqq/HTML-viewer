import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/storage/editor_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('EditorStorage seeds the starter template for a fresh editor', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = EditorStorage(prefs);

    final draft = storage.loadDraft();
    expect(draft, contains('<!DOCTYPE html>'));
    expect(draft, contains('你好，方块世界'));
  });

  test('EditorStorage roundtrips an explicitly saved draft', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = EditorStorage(prefs);

    await storage.saveDraft('<p>hi</p>');
    expect(storage.loadDraft(), '<p>hi</p>');

    // An emptied draft stays empty (no template re-seeding).
    await storage.saveDraft('');
    expect(storage.loadDraft(), '');
  });
}
