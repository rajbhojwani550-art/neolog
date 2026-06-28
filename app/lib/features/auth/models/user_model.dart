class UserModel {
  final String id;
  final String name;
  final String email;
  final String hospital;
  final String designation;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.hospital,
    required this.designation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hospital: json['hospital'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'hospital': hospital,
        'designation': designation,
      };
}
