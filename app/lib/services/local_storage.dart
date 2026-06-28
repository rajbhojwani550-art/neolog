import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

class LocalStorage {
  Box _box(String name) => Hive.box(name);

  // Generic CRUD for any box
  Future<void> save(String boxName, String key, Map<String, dynamic> data) async {
    await _box(boxName).put(key, jsonEncode(data));
  }

  Map<String, dynamic>? get(String boxName, String key) {
    final raw = _box(boxName).get(key);
    if (raw == null) return null;
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> getAll(String boxName) {
    return _box(boxName)
        .values
        .map((v) => jsonDecode(v as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> remove(String boxName, String key) async {
    await _box(boxName).delete(key);
  }

  Future<void> clearBox(String boxName) async {
    await _box(boxName).clear();
  }

  // Filtered queries
  List<Map<String, dynamic>> query(
    String boxName,
    bool Function(Map<String, dynamic>) predicate,
  ) {
    return getAll(boxName).where(predicate).toList();
  }

  // Babies
  Future<void> saveBaby(Map<String, dynamic> baby) async {
    await save('babies', baby['id'] as String, baby);
  }

  List<Map<String, dynamic>> getAllBabies() => getAll('babies');

  Map<String, dynamic>? getBaby(String id) => get('babies', id);

  // Daily Logs
  Future<void> saveLog(Map<String, dynamic> log) async {
    await save('daily_logs', log['id'] as String, log);
  }

  List<Map<String, dynamic>> getLogsForBaby(String babyId) {
    return query('daily_logs', (log) => log['babyId'] == babyId);
  }

  // Growth
  Future<void> saveGrowth(Map<String, dynamic> measurement) async {
    await save('growth', measurement['id'] as String, measurement);
  }

  List<Map<String, dynamic>> getGrowthForBaby(String babyId) {
    return query('growth', (m) => m['babyId'] == babyId);
  }

  // Screenings
  Future<void> saveScreening(String type, Map<String, dynamic> screening) async {
    await save('screenings', screening['id'] as String, {
      ...screening,
      '_type': type,
    });
  }

  List<Map<String, dynamic>> getScreeningsForBaby(String babyId, String type) {
    return query('screenings',
        (s) => s['babyId'] == babyId && s['_type'] == type);
  }

  // Medications
  Future<void> saveMedication(Map<String, dynamic> med) async {
    await save('medications', med['id'] as String, med);
  }

  List<Map<String, dynamic>> getMedicationsForBaby(String babyId) {
    return query('medications', (m) => m['babyId'] == babyId);
  }

  // Events
  Future<void> saveEvent(Map<String, dynamic> event) async {
    await save('events', event['id'] as String, event);
  }

  List<Map<String, dynamic>> getEventsForBaby(String babyId) {
    return query('events', (e) => e['babyId'] == babyId);
  }

  // Investigations
  Future<void> saveInvestigation(Map<String, dynamic> inv) async {
    await save('investigations', inv['id'] as String, inv);
  }

  List<Map<String, dynamic>> getInvestigationsForBaby(String babyId) {
    return query('investigations', (i) => i['babyId'] == babyId);
  }
}
