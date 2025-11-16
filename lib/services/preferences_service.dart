import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const String _defaultEventKey = 'default_event_id';
  String? _defaultEventId;

  String? get defaultEventId => _defaultEventId;

  PreferencesService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultEventId = prefs.getString(_defaultEventKey);
    notifyListeners();
  }

  Future<void> setDefaultEvent(String? eventId) async {
    _defaultEventId = eventId;
    final prefs = await SharedPreferences.getInstance();
    if (eventId != null) {
      await prefs.setString(_defaultEventKey, eventId);
    } else {
      await prefs.remove(_defaultEventKey);
    }
    notifyListeners();
  }

  Future<void> clearDefaultEvent() async {
    await setDefaultEvent(null);
  }
}
