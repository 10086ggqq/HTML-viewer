[🇨🇳 中文](README.md) | [🇺🇸 English](README_EN.md)

<p align="center">
  <img src="assets/ico/MinecraftHTMLview.png" width="120" alt="Minecraft HTMLViewer app icon" />
</p>

# Minecraft HTMLViewer

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/10086ggqq/HTML-viewer?style=social)](https://github.com/10086ggqq/HTML-viewer/stargazers)

**A Minecraft-styled HTML viewer and front-end debugging toolkit for Android — open, read, and debug web pages on your phone like exploring a blocky new world.**

This is not just another WebView wrapper. It ships with a full source-code reader, a live Console panel, ZIP project import/export, and native sharing — all wrapped in a pixel-art UI with chest-opening page transitions and an XP-bar loading overlay that make mobile front-end work feel like a quest.

## Features

- [x] HTML preview — open local files or pick folders via Android SAF; relative resources (CSS / JS / images) resolve correctly
- [x] Handwritten HTML editor — Code/Preview tabs on phones and a side-by-side split at ≥700dp; live preview via loadHtmlString, HTML file import, clipboard paste, starter template, copy-all, font-size control, clear, and "save as file" (into handwritten/, opening the viewer right after); the draft autosaves (800ms debounce) and the Console panel stays available
- [x] Source viewer — syntax highlighting for HTML / CSS / JS / JSON / Markdown in a Minecraft-inspired palette (XP green, diamond blue, gold, redstone red)
- [x] Reader tooling — line-number gutter, in-file search (case-insensitive, jump up/down, match counter), font-size control, and a word-wrap toggle
- [x] Console panel — hooks `console.log / warn / error`, captures `window.onerror` and unhandled promise rejections; color-coded levels, long-press to copy, one-tap clear
- [x] Project management — import ZIP projects with path-traversal (zip-slip) protection and automatic entry-point detection, export back to ZIP, share via the Android share sheet
- [x] History & favorites — recent files and projects on separate lists with a configurable cap (5 / 10 / 20 / 50), plus a dedicated favorites page
- [x] File awareness — get a "file has changed" prompt when a previously opened file is modified externally, or a themed error page if it has been deleted
- [x] Reading experience — chest-opening page transitions, a "Loading World" overlay, fullscreen mode, and hardware back that navigates web history before leaving the page
- [x] Tablet layout — NavigationRail at ≥600dp and a side-by-side preview/source split at ≥700dp
- [x] Settings hub — JavaScript toggle, external-network toggle, reader preferences (font size / wrap / line numbers / default tab), plus settings export / import / reset

> Note: console calls fired very early in page load (before `DOMContentLoaded`) may be missed, and the Console panel is disabled when JavaScript is turned off.

## Getting Started

### 1. Prerequisites

| Requirement | Version |
| ----------- | ------- |
| Flutter SDK | 3.27.x |
| Dart SDK | ^3.6.0 |
| Android Studio + Android SDK | AGP 8.1.1+ |
| Android device / emulator | Android 5.0+ |

### 2. Clone and install dependencies

```bash
git clone https://github.com/10086ggqq/HTML-viewer.git
cd HTML-viewer
flutter pub get
```

### 3. Configure signing (optional, release builds only)

No signing files are included in the repository. Skip this step for local debugging. For release builds, create `android/key.properties`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=your-alias
storeFile=../app/your-release-key.jks
```

> `key.properties` and `*.jks` are already listed in `.gitignore` — never commit them.

### 4. Run and build

```bash
# Run on a connected device or emulator
flutter run

# Build a release APK
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

## Tech Stack

| Technology | Purpose | Version |
| ---------- | ------- | ------- |
| Flutter | Cross-platform UI framework | 3.27.x / Dart ^3.6.0 |
| flutter_riverpod | State management & DI | ^2.6.1 |
| webview_flutter (+_android) | HTML page rendering | ^4.10.0 |
| highlight | Pure-Dart syntax highlighting (no native deps) | ^0.7.0 |
| archive | ZIP project import / export | ^3.6.1 |
| file_picker | Android SAF file & folder picking | ^8.1.6 |
| share_plus | Android share sheet (files / ZIPs) | ^10.1.4 |
| path_provider | App working directory (extracted projects) | ^2.1.4 |
| shared_preferences | Settings / history / favorites persistence | ^2.3.4 |
| flutter_launcher_icons | Adaptive app icon generation | ^0.14.3 |
| Press Start 2P | Pixel headline font (bundled, OFL) | - |

## Project Structure

```text
HTML-viewer/
├── lib/
│   ├── main.dart                       # Entry point: boots persistence, then the app
│   ├── app/                            # App skeleton
│   │   ├── app.dart                    # MaterialApp & routing
│   │   ├── root_shell.dart             # Bottom-nav / NavigationRail shell
│   │   ├── theme.dart                  # Minecraft color scheme & theme
│   │   └── chest_page_transition.dart  # Chest-opening page transition
│   ├── core/
│   │   └── services/                   # file_picker / zip / share service wrappers
│   ├── data/models/html_entry.dart     # File & project data models
│   ├── features/
│   │   ├── home/                       # Home screen
│   │   ├── files/                      # File lists, history controllers, open flow
│   │   ├── favorites/                  # Favorites page
│   │   ├── editor/                     # Handwritten HTML editor (code / live preview)
│   │   ├── viewer/                     # WebView preview (preview/source tabs)
│   │   ├── source/                     # Source reader & syntax highlighting
│   │   ├── developer/                  # Console panel
│   │   └── settings/                   # Settings model / controller / page
│   ├── storage/                        # Settings / history / editor-draft storage layer
│   └── widgets/                        # Pixel widget library (buttons / cards / icons / progress)
├── test/                               # Unit & widget tests
├── assets/
│   ├── fonts/                          # Press Start 2P font (OFL)
│   └── ico/                            # App icon source image
└── android/                            # Android project & signing config
```

## Screenshots / Demo

<p align="center">
  <img src="assets/ico/MinecraftHTMLview.png" width="96" alt="App icon" />
</p>

> Screenshots are on the way — on-device captures (home screen, preview/source split, Console panel, ZIP import flow) will be added under `docs/screenshots/`.

## License

This project is released under the [MIT License](LICENSE).

The bundled Press Start 2P font (`assets/fonts/PressStart2P-Regular.ttf`) is licensed under the [SIL Open Font License 1.1](https://openfontlicense.org/) and may be freely redistributed with the app.

## Contributing

Issues and pull requests are welcome!

**Issue guidelines**

- Bug reports should include: steps to reproduce, expected vs. actual behavior, device model and Android version, and (optionally) a screenshot of the console output
- Feature requests should describe: the use case, the interaction you have in mind, and why the current feature set falls short

**Pull request workflow**

1. Fork this repository
2. Create a branch: `git checkout -b feat/your-feature` (use `fix/` for bugfixes, `docs/` for documentation)
3. Commit your changes: `git commit -m "feat: brief description"`
4. Push and open a PR describing the change and how you tested it
5. Address review feedback, then your PR gets merged
