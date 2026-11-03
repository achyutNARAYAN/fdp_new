class UserModel {
  final String id;
  final String customerId;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool termsAccepted;
  final bool isEmailVerified;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    this.customerId = '',
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.termsAccepted = false,
    this.isEmailVerified = false,
    this.avatarUrl,
  });

  int get profileCompletionPercentage {
    int score = 0;
    if (fullName.trim().isNotEmpty) score += 35;
    if (mobileNumber.trim().isNotEmpty) score += 35;
    if (email != null && email!.trim().isNotEmpty) score += 15;
    if (dateOfBirth != null) score += 15;
    return score;
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length > 1 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  UserModel copyWith({
    String? fullName,
    String? mobileNumber,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    bool? termsAccepted,
    bool? isEmailVerified,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      customerId: customerId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      fullName: json['name']?.toString() ?? '',
      mobileNumber: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      gender: json['gender']?.toString(),
      termsAccepted: json['termsAccepted'] == true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {'name': fullName, 'phone': mobileNumber};
  }
}

