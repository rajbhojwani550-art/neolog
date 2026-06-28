import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/local_storage.dart';
import '../models/baby_model.dart';

const _uuid = Uuid();

class BabiesNotifier extends StateNotifier<List<BabyModel>> {
  final LocalStorage _storage;

  BabiesNotifier(this._storage) : super([]) {
    _loadBabies();
  }

  void _loadBabies() {
    final data = _storage.getAllBabies();
    state = data.map((json) => BabyModel.fromJson(json)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<BabyModel> addBaby({
    required String mrn,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required int gaWeeks,
    required int gaDays,
    required int birthWeightGrams,
    required String sex,
    required String motherName,
    required String fatherName,
    int? motherAge,
    required String modeOfDelivery,
    int? apgarScore1min,
    int? apgarScore5min,
    required DateTime admissionDate,
    required String admissionReason,
    required String antenatalSteroids,
    String? antenatalHistory,
  }) async {
    final baby = BabyModel(
      id: _uuid.v4(),
      mrn: mrn,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gaWeeks: gaWeeks,
      gaDays: gaDays,
      birthWeightGrams: birthWeightGrams,
      sex: sex,
      motherName: motherName,
      fatherName: fatherName,
      motherAge: motherAge,
      modeOfDelivery: modeOfDelivery,
      apgarScore1min: apgarScore1min,
      apgarScore5min: apgarScore5min,
      admissionDate: admissionDate,
      admissionReason: admissionReason,
      antenatalSteroids: antenatalSteroids,
      antenatalHistory: antenatalHistory,
      status: 'admitted',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveBaby(baby.toJson());
    state = [baby, ...state];
    return baby;
  }

  Future<void> updateBaby(BabyModel baby) async {
    await _storage.saveBaby(baby.toJson());
    state = state.map((b) => b.id == baby.id ? baby : b).toList();
  }

  Future<void> dischargeBaby(String id, DateTime dischargeDate) async {
    final baby = state.firstWhere((b) => b.id == id);
    final updated = baby.copyWith(
      status: 'discharged',
      dischargeDate: dischargeDate,
    );
    await updateBaby(updated);
  }

  BabyModel? getBaby(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (_) {
      final json = _storage.getBaby(id);
      if (json != null) return BabyModel.fromJson(json);
      return null;
    }
  }

  List<BabyModel> searchBabies(String query) {
    final lower = query.toLowerCase();
    return state
        .where((b) =>
            b.fullName.toLowerCase().contains(lower) ||
            b.mrn.toLowerCase().contains(lower))
        .toList();
  }

  List<BabyModel> filterByStatus(String status) {
    return state.where((b) => b.status == status).toList();
  }
}

final babiesProvider =
    StateNotifierProvider<BabiesNotifier, List<BabyModel>>((ref) {
  return BabiesNotifier(ref.read(localStorageProvider));
});

final babyProvider = Provider.family<BabyModel?, String>((ref, id) {
  final babies = ref.watch(babiesProvider);
  try {
    return babies.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});
