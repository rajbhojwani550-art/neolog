class DailyLogModel {
  final String id;
  final String babyId;
  final DateTime logDate;
  final int dayOfLife;
  final String correctedGA;

  // Vitals
  final int? heartRate;
  final int? respiratoryRate;
  final double? temperature;
  final int? spo2;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? weight;
  final double? headCircumference;
  final double? length;

  // Respiratory
  final String respiratorySupport;
  final int? fio2Percent;
  final int? peep;
  final int? pip;
  final int? rate;
  final double? tidalVolume;
  final int? cpapPressure;

  // Feeds
  final String feedType;
  final double? feedVolumeMlPerKg;
  final double? feedCaloriesDensity;
  final double? totalFluidMlPerKg;
  final double? ivfRate;
  final String? ivfType;
  final bool tpn;

  // Systemic examination
  final String? generalExam;
  final String? cnsExam;
  final String? cvExam;
  final String? respiratoryExam;
  final String? abdomenExam;
  final String? skinExam;
  final String? eyesExam;

  // Assessment
  final List<String> activeProblemsList;
  final String? plan;
  final String? attendingDoctor;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyLogModel({
    required this.id,
    required this.babyId,
    required this.logDate,
    required this.dayOfLife,
    required this.correctedGA,
    this.heartRate,
    this.respiratoryRate,
    this.temperature,
    this.spo2,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.weight,
    this.headCircumference,
    this.length,
    this.respiratorySupport = 'room air',
    this.fio2Percent,
    this.peep,
    this.pip,
    this.rate,
    this.tidalVolume,
    this.cpapPressure,
    this.feedType = 'NPO',
    this.feedVolumeMlPerKg,
    this.feedCaloriesDensity,
    this.totalFluidMlPerKg,
    this.ivfRate,
    this.ivfType,
    this.tpn = false,
    this.generalExam,
    this.cnsExam,
    this.cvExam,
    this.respiratoryExam,
    this.abdomenExam,
    this.skinExam,
    this.eyesExam,
    this.activeProblemsList = const [],
    this.plan,
    this.attendingDoctor,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as String,
      babyId: json['babyId'] as String,
      logDate: DateTime.parse(json['logDate'] as String),
      dayOfLife: json['dayOfLife'] as int? ?? 1,
      correctedGA: json['correctedGA'] as String? ?? '',
      heartRate: json['heartRate'] as int?,
      respiratoryRate: json['respiratoryRate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      spo2: json['spo2'] as int?,
      bloodPressureSystolic: json['bloodPressureSystolic'] as int?,
      bloodPressureDiastolic: json['bloodPressureDiastolic'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      headCircumference: (json['headCircumference'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      respiratorySupport: json['respiratorySupport'] as String? ?? 'room air',
      fio2Percent: json['fio2Percent'] as int?,
      peep: json['peep'] as int?,
      pip: json['pip'] as int?,
      rate: json['rate'] as int?,
      tidalVolume: (json['tidalVolume'] as num?)?.toDouble(),
      cpapPressure: json['cpapPressure'] as int?,
      feedType: json['feedType'] as String? ?? 'NPO',
      feedVolumeMlPerKg: (json['feedVolumeMlPerKg'] as num?)?.toDouble(),
      feedCaloriesDensity: (json['feedCaloriesDensity'] as num?)?.toDouble(),
      totalFluidMlPerKg: (json['totalFluidMlPerKg'] as num?)?.toDouble(),
      ivfRate: (json['ivfRate'] as num?)?.toDouble(),
      ivfType: json['ivfType'] as String?,
      tpn: json['tpn'] as bool? ?? false,
      generalExam: json['generalExam'] as String?,
      cnsExam: json['cnsExam'] as String?,
      cvExam: json['cvExam'] as String?,
      respiratoryExam: json['respiratoryExam'] as String?,
      abdomenExam: json['abdomenExam'] as String?,
      skinExam: json['skinExam'] as String?,
      eyesExam: json['eyesExam'] as String?,
      activeProblemsList: (json['activeProblemsList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      plan: json['plan'] as String?,
      attendingDoctor: json['attendingDoctor'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'babyId': babyId,
        'logDate': logDate.toIso8601String(),
        'dayOfLife': dayOfLife,
        'correctedGA': correctedGA,
        'heartRate': heartRate,
        'respiratoryRate': respiratoryRate,
        'temperature': temperature,
        'spo2': spo2,
        'bloodPressureSystolic': bloodPressureSystolic,
        'bloodPressureDiastolic': bloodPressureDiastolic,
        'weight': weight,
        'headCircumference': headCircumference,
        'length': length,
        'respiratorySupport': respiratorySupport,
        'fio2Percent': fio2Percent,
        'peep': peep,
        'pip': pip,
        'rate': rate,
        'tidalVolume': tidalVolume,
        'cpapPressure': cpapPressure,
        'feedType': feedType,
        'feedVolumeMlPerKg': feedVolumeMlPerKg,
        'feedCaloriesDensity': feedCaloriesDensity,
        'totalFluidMlPerKg': totalFluidMlPerKg,
        'ivfRate': ivfRate,
        'ivfType': ivfType,
        'tpn': tpn,
        'generalExam': generalExam,
        'cnsExam': cnsExam,
        'cvExam': cvExam,
        'respiratoryExam': respiratoryExam,
        'abdomenExam': abdomenExam,
        'skinExam': skinExam,
        'eyesExam': eyesExam,
        'activeProblemsList': activeProblemsList,
        'plan': plan,
        'attendingDoctor': attendingDoctor,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
