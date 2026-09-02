import 'dart:convert';

/// App theme mode preference.
enum AppThemeMode { system, light, dark }

/// How strong the Minecraft-style visual language is applied.
enum PixelStrength { standard, pixel }

/// Which tab the viewer page opens on.
enum ViewerTab { preview, source }

/// User-facing application settings.
class Settings {
  const Settings({
    this.themeMode = AppThemeMode.system,
    this.pixelFont = true,
    this.animations = true,
    this.uiStrength = PixelStrength.pixel,
    this.cornerRadius = 6,
    this.javascript = true,
    this.allowNetwork = true,
    this.recentLimit = 20,
    this.codeFontSize = 13.0,
    this.codeWordWrap = true,
    this.showLineNumbers = true,
    this.defaultViewerTab = ViewerTab.preview,
  });

  final AppThemeMode themeMode;
  final bool pixelFont;
  final bool animations;
  final PixelStrength uiStrength;
  final double cornerRadius;

  /// Whether web pages may run JavaScript in the preview WebView.
  final bool javascript;

  /// Whether the preview may navigate to external http(s) addresses.
  /// When off, only local file navigation is allowed.
  final bool allowNetwork;

  /// Maximum number of remembered recent files.
  final int recentLimit;

  // Reading (source viewer)
  final double codeFontSize;
  final bool codeWordWrap;
  final bool showLineNumbers;
  final ViewerTab defaultViewerTab;

  Settings copyWith({
    AppThemeMode? themeMode,
    bool? pixelFont,
    bool? animations,
    PixelStrength? uiStrength,
    double? cornerRadius,
    bool? javascript,
    bool? allowNetwork,
    int? recentLimit,
    double? codeFontSize,
    bool? codeWordWrap,
    bool? showLineNumbers,
    ViewerTab? defaultViewerTab,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      pixelFont: pixelFont ?? this.pixelFont,
      animations: animations ?? this.animations,
      uiStrength: uiStrength ?? this.uiStrength,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      javascript: javascript ?? this.javascript,
      allowNetwork: allowNetwork ?? this.allowNetwork,
      recentLimit: recentLimit ?? this.recentLimit,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      codeWordWrap: codeWordWrap ?? this.codeWordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      defaultViewerTab: defaultViewerTab ?? this.defaultViewerTab,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'pixelFont': pixelFont,
        'animations': animations,
        'uiStrength': uiStrength.name,
        'cornerRadius': cornerRadius,
        'javascript': javascript,
        'allowNetwork': allowNetwork,
        'recentLimit': recentLimit,
        'codeFontSize': codeFontSize,
        'codeWordWrap': codeWordWrap,
        'showLineNumbers': showLineNumbers,
        'defaultViewerTab': defaultViewerTab.name,
      };

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeMode:
          AppThemeMode.values.asNameMap()[json['themeMode'] as String?] ??
              AppThemeMode.system,
      pixelFont: json['pixelFont'] as bool? ?? true,
      animations: json['animations'] as bool? ?? true,
      uiStrength:
          PixelStrength.values.asNameMap()[json['uiStrength'] as String?] ??
              PixelStrength.pixel,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 6,
      javascript: json['javascript'] as bool? ?? true,
      allowNetwork: json['allowNetwork'] as bool? ?? true,
      recentLimit: json['recentLimit'] as int? ?? 20,
      codeFontSize: (json['codeFontSize'] as num?)?.toDouble() ?? 13.0,
      codeWordWrap: json['codeWordWrap'] as bool? ?? true,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      defaultViewerTab:
          ViewerTab.values.asNameMap()[json['defaultViewerTab'] as String?] ??
              ViewerTab.preview,
    );
  }

  factory Settings.fromJsonString(String raw) =>
      Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
