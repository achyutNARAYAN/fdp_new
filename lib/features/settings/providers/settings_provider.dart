import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String selectedLanguage; // 'English', 'हिन्दी (Hindi)', 'ಕನ್ನಡ (Kannada)'
  final bool orderNotificationsEnabled;
  final bool promotionalNotificationsEnabled;
  final bool hapticsEnabled;

  const SettingsState({
    this.selectedLanguage = 'English',
    this.orderNotificationsEnabled = true,
    this.promotionalNotificationsEnabled = false,
    this.hapticsEnabled = true,
  });

  SettingsState copyWith({
    String? selectedLanguage,
    bool? orderNotificationsEnabled,
    bool? promotionalNotificationsEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      orderNotificationsEnabled: orderNotificationsEnabled ?? this.orderNotificationsEnabled,
      promotionalNotificationsEnabled: promotionalNotificationsEnabled ?? this.promotionalNotificationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setLanguage(String lang) {
    state = state.copyWith(selectedLanguage: lang);
  }

  void toggleOrderNotifications(bool val) {
    state = state.copyWith(orderNotificationsEnabled: val);
  }

  void togglePromotionalNotifications(bool val) {
    state = state.copyWith(promotionalNotificationsEnabled: val);
  }

  void toggleHaptics(bool val) {
    state = state.copyWith(hapticsEnabled: val);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

