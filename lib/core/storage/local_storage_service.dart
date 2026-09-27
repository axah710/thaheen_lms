import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service wrapper around SharedPreferences providing type-safe persistence
/// and corrupt-data recovery for Thaheen LMS.
class LocalStorageService {
  static const String progressKey = 'thaheen_progress_v1';

  final SharedPreferences _prefs;

  const LocalStorageService(this._prefs);

  /// Initializes LocalStorageService with standard SharedPreferences instance.
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  /// Retrieves the raw string stored under [key].
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'LocalStorageService.getString failed for key $key: $e\n$st',
        );
      }
      return null;
    }
  }

  /// Persists a string [value] under [key].
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'LocalStorageService.setString failed for key $key: $e\n$st',
        );
      }
      return false;
    }
  }

  /// Removes the value associated with [key].
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalStorageService.remove failed for key $key: $e\n$st');
      }
      return false;
    }
  }

  /// Clears all stored key-value pairs.
  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalStorageService.clear failed: $e\n$st');
      }
      return false;
    }
  }

  /// Reads and safely decodes the progress envelope JSON.
  ///
  /// Guarantees:
  /// - Returns decoded `Map<String, dynamic>` if valid JSON.
  /// - If uninitialized (null), returns an empty map.
  /// - If JSON is corrupt/unparseable, resets storage to empty and invokes [onCorruptDataRecovered] if provided.
  Map<String, dynamic> getProgressEnvelopeJson({
    VoidCallback? onCorruptDataRecovered,
  }) {
    final raw = getString(progressKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Expected JSON object for progress envelope');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Corrupted progress envelope detected: $e\n$st');
      }
      // Reset corrupted envelope to empty for data integrity
      remove(progressKey);
      onCorruptDataRecovered?.call();
      return <String, dynamic>{};
    }
  }

  /// Saves the progress envelope [map] as JSON string under [progressKey].
  Future<bool> saveProgressEnvelopeJson(Map<String, dynamic> map) async {
    try {
      final jsonString = jsonEncode(map);
      return await setString(progressKey, jsonString);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('saveProgressEnvelopeJson failed: $e\n$st');
      }
      return false;
    }
  }
}
