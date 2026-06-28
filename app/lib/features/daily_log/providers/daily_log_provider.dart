import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/local_storage.dart';
import '../models/daily_log_model.dart';

const _uuid = Uuid();

class DailyLogNotifier extends StateNotifier<List<DailyLogModel>> {
  final LocalStorage _storage;
  final String babyId;

  DailyLogNotifier(this._storage, this.babyId) : super([]) {
    _loadLogs();
  }

  void _loadLogs() {
    final data = _storage.getLogsForBaby(babyId);
    state = data.map((json) => DailyLogModel.fromJson(json)).toList()
      ..sort((a, b) => b.logDate.compareTo(a.logDate));
  }

  Future<DailyLogModel> addLog(Map<String, dynamic> logData) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final fullData = {
      'id': id,
      'babyId': babyId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      ...logData,
    };

    await _storage.saveLog(fullData);
    final log = DailyLogModel.fromJson(fullData);
    state = [log, ...state];
    return log;
  }

  Future<void> updateLog(String logId, Map<String, dynamic> logData) async {
    final existing = state.firstWhere((l) => l.id == logId);
    final updated = {
      ...existing.toJson(),
      ...logData,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _storage.saveLog(updated);
    state = state.map((l) {
      if (l.id == logId) return DailyLogModel.fromJson(updated);
      return l;
    }).toList();
  }

  DailyLogModel? getLog(String logId) {
    try {
      return state.firstWhere((l) => l.id == logId);
    } catch (_) {
      return null;
    }
  }
}

final dailyLogProvider = StateNotifierProvider.family<DailyLogNotifier,
    List<DailyLogModel>, String>((ref, babyId) {
  return DailyLogNotifier(ref.read(localStorageProvider), babyId);
});
