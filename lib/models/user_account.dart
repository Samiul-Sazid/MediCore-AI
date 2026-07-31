class UserAccount {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime? dob;
  final DateTime createdAt;

  UserAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.dob,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ""}${lastName.isNotEmpty ? lastName[0] : ""}'.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'passwordHash': passwordHash,
      'salt': salt,
      'dob': dob?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<dynamic, dynamic> map) {
    return UserAccount(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      salt: map['salt'] ?? '',
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
