class BabyModel {
  final String id;
  final String mrn;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final int gaWeeks;
  final int gaDays;
  final int birthWeightGrams;
  final String sex;
  final String motherName;
  final String fatherName;
  final int? motherAge;
  final String modeOfDelivery;
  final int? apgarScore1min;
  final int? apgarScore5min;
  final DateTime admissionDate;
  final String admissionReason;
  final String antenatalSteroids;
  final String? antenatalHistory;
  final DateTime? dischargeDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BabyModel({
    required this.id,
    required this.mrn,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gaWeeks,
    required this.gaDays,
    required this.birthWeightGrams,
    required this.sex,
    required this.motherName,
    required this.fatherName,
    this.motherAge,
    required this.modeOfDelivery,
    this.apgarScore1min,
    this.apgarScore5min,
    required this.admissionDate,
    required this.admissionReason,
    required this.antenatalSteroids,
    this.antenatalHistory,
    this.dischargeDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get gestationalAge => '$gaWeeks+$gaDays';

  int get dayOfLife {
    return DateTime.now().difference(dateOfBirth).inDays + 1;
  }

  String get correctedGA {
    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysLived = DateTime.now().difference(dateOfBirth).inDays;
    final totalDays = totalDaysAtBirth + daysLived;
    return '${totalDays ~/ 7}+${totalDays % 7}';
  }

  double get correctedGAWeeks {
    final totalDaysAtBirth = gaWeeks * 7 + gaDays;
    final daysLived = DateTime.now().difference(dateOfBirth).inDays;
    return (totalDaysAtBirth + daysLived) / 7.0;
  }

  bool get isPreterm => (gaWeeks * 7 + gaDays) < (37 * 7);

  factory BabyModel.fromJson(Map<String, dynamic> json) {
    return BabyModel(
      id: json['id'] as String,
      mrn: json['mrn'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gaWeeks: json['gaWeeks'] as int? ?? 0,
      gaDays: json['gaDays'] as int? ?? 0,
      birthWeightGrams: json['birthWeightGrams'] as int? ?? 0,
      sex: json['sex'] as String? ?? 'male',
      motherName: json['motherName'] as String? ?? '',
      fatherName: json['fatherName'] as String? ?? '',
      motherAge: json['motherAge'] as int?,
      modeOfDelivery: json['modeOfDelivery'] as String? ?? 'NVD',
      apgarScore1min: json['apgarScore1min'] as int?,
      apgarScore5min: json['apgarScore5min'] as int?,
      admissionDate: DateTime.parse(json['admissionDate'] as String),
      admissionReason: json['admissionReason'] as String? ?? '',
      antenatalSteroids: json['antenatalSteroids'] as String? ?? 'none',
      antenatalHistory: json['antenatalHistory'] as String?,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.parse(json['dischargeDate'] as String)
          : null,
      status: json['status'] as String? ?? 'admitted',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mrn': mrn,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gaWeeks': gaWeeks,
        'gaDays': gaDays,
        'birthWeightGrams': birthWeightGrams,
        'sex': sex,
        'motherName': motherName,
        'fatherName': fatherName,
        'motherAge': motherAge,
        'modeOfDelivery': modeOfDelivery,
        'apgarScore1min': apgarScore1min,
        'apgarScore5min': apgarScore5min,
        'admissionDate': admissionDate.toIso8601String(),
        'admissionReason': admissionReason,
        'antenatalSteroids': antenatalSteroids,
        'antenatalHistory': antenatalHistory,
        'dischargeDate': dischargeDate?.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BabyModel copyWith({
    String? mrn,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    int? gaWeeks,
    int? gaDays,
    int? birthWeightGrams,
    String? sex,
    String? motherName,
    String? fatherName,
    int? motherAge,
    String? modeOfDelivery,
    int? apgarScore1min,
    int? apgarScore5min,
    DateTime? admissionDate,
    String? admissionReason,
    String? antenatalSteroids,
    String? antenatalHistory,
    DateTime? dischargeDate,
    String? status,
  }) {
    return BabyModel(
      id: id,
      mrn: mrn ?? this.mrn,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gaWeeks: gaWeeks ?? this.gaWeeks,
      gaDays: gaDays ?? this.gaDays,
      birthWeightGrams: birthWeightGrams ?? this.birthWeightGrams,
      sex: sex ?? this.sex,
      motherName: motherName ?? this.motherName,
      fatherName: fatherName ?? this.fatherName,
      motherAge: motherAge ?? this.motherAge,
      modeOfDelivery: modeOfDelivery ?? this.modeOfDelivery,
      apgarScore1min: apgarScore1min ?? this.apgarScore1min,
      apgarScore5min: apgarScore5min ?? this.apgarScore5min,
      admissionDate: admissionDate ?? this.admissionDate,
      admissionReason: admissionReason ?? this.admissionReason,
      antenatalSteroids: antenatalSteroids ?? this.antenatalSteroids,
      antenatalHistory: antenatalHistory ?? this.antenatalHistory,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
