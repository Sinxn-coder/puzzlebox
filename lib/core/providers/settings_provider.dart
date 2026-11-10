import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/neo.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

/// Persisted app-wide settings.
class SettingsNotifier extends Notifier<SettingsState> {
  Future<void> setPalette(int value) async {
    final clamped = value.clamp(0, 7);
    await ref.read(sharedPreferencesProvider).setInt('settings_palette', clamped);
    state = state.copyWith(palette: clamped);
  }

  static const _themeKey = 'settings_theme_mode';
  static const _hapticsKey = 'settings_haptics';
  static const _hardModeKey = 'settings_hard_mode';
  static const _difficultyKey = 'settings_default_difficulty';
  static const _neoStyleKey = 'settings_neo_style';
  static const _textScaleKey = 'settings_text_scale';
  static const _colorblindKey = 'settings_colorblind';
  static const _soundKey = 'settings_sounds';

  /// Text size choices offered in settings. 0 follows the system setting.
  static const textScaleOptions = <double>[0, 1.0, 1.15, 1.3];

  /// Keys that only exist once someone has used the app. Their presence means
  /// an existing player, who keeps the original defaults (Minimal Slate,
  /// light theme, haptics off) so nothing changes under them after updating.
  static bool _isExistingPlayer(SharedPreferences prefs) =>
      prefs.getKeys().any(
        (k) =>
            k == 'engagement_v1' ||
            k == 'installation_puzzle_seed' ||
            k == 'settings_notification_prompt_handled' ||
            k == 'has_seen_intro_v1' ||
            k.startsWith('has_seen_rules_') ||
            k.startsWith('progress_v1_') ||
            k.startsWith('settings_') ||
            k.endsWith('_stats'),
      );

  /// Fresh installs start colourful, follow the phone's light/dark setting
  /// and have light haptics on. Saved once so they never flip later.
  static void _applyNewInstallDefaults(SharedPreferences prefs) {
    if (prefs.containsKey('settings_palette') || _isExistingPlayer(prefs)) return;
    prefs.setInt('settings_palette', 0);
    prefs.setInt(_themeKey, ThemeMode.system.index);
    prefs.setBool(_hapticsKey, true);
  }

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _applyNewInstallDefaults(prefs);
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    final haptics = prefs.getBool(_hapticsKey) ?? false;
    final hardMode = prefs.getBool(_hardModeKey) ?? false;
    final defaultDifficulty = prefs.getString(_difficultyKey) ?? 'Medium';
    return SettingsState(
      themeMode: ThemeMode.values[themeIndex.clamp(0, 2)],
      palette: (prefs.getInt('settings_palette') ?? 7).clamp(0, 7),
      hapticsEnabled: haptics,
      hardModeEnabled: hardMode,
      defaultDifficulty: defaultDifficulty,
      neoStyle: prefs.getString(_neoStyleKey) == NeoStyle.soft.name
          ? NeoStyle.soft
          : NeoStyle.bold,
      textScale: textScaleOptions.contains(prefs.getDouble(_textScaleKey))
          ? prefs.getDouble(_textScaleKey)!
          : 0,
      colorblindMode: prefs.getBool(_colorblindKey) ?? false,
      soundEnabled: prefs.getBool(_soundKey) ?? false,
    );
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_soundKey, enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setNeoStyle(NeoStyle style) async {
    await ref.read(sharedPreferencesProvider).setString(_neoStyleKey, style.name);
    state = state.copyWith(neoStyle: style);
  }

  Future<void> setTextScale(double scale) async {
    if (!textScaleOptions.contains(scale)) return;
    await ref.read(sharedPreferencesProvider).setDouble(_textScaleKey, scale);
    state = state.copyWith(textScale: scale);
  }

  Future<void> setColorblindMode(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_colorblindKey, enabled);
    state = state.copyWith(colorblindMode: enabled);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hapticsKey, enabled);
    state = state.copyWith(hapticsEnabled: enabled);
  }

  Future<void> setHardModeEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_hardModeKey, enabled);
    state = state.copyWith(hardModeEnabled: enabled);
  }

  Future<void> setDefaultDifficulty(String difficulty) async {
    if (!const ['Easy', 'Medium', 'Hard'].contains(difficulty)) return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_difficultyKey, difficulty);
    state = state.copyWith(defaultDifficulty: difficulty);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsState {
  final int palette;
  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool hardModeEnabled;
  final String defaultDifficulty;
  final NeoStyle neoStyle;

  /// 0 follows the system text size; otherwise a fixed scale factor.
  final double textScale;

  /// Swaps green/yellow style feedback colours for a blue/orange palette and
  /// adds shape cues so colour is never the only signal.
  final bool colorblindMode;

  /// Soft system click on taps and a chime on wins (off by default).
  final bool soundEnabled;

  const SettingsState({
    this.palette = 7,
    required this.themeMode,
    this.hapticsEnabled = false,
    this.hardModeEnabled = false,
    this.defaultDifficulty = 'Medium',
    this.neoStyle = NeoStyle.bold,
    this.textScale = 0,
    this.colorblindMode = false,
    this.soundEnabled = false,
  });

  SettingsState copyWith({
    int? palette,
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? hardModeEnabled,
    String? defaultDifficulty,
    NeoStyle? neoStyle,
    double? textScale,
    bool? colorblindMode,
    bool? soundEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hardModeEnabled: hardModeEnabled ?? this.hardModeEnabled,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
      neoStyle: neoStyle ?? this.neoStyle,
      textScale: textScale ?? this.textScale,
      colorblindMode: colorblindMode ?? this.colorblindMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
