/// User model for DivineQueue app
class UserModel {
  final String uid;
  final String name;
  final String email;
  final int points;
  final int queuePosition;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.points = 0,
    this.queuePosition = 0,
    this.createdAt,
  });

  /// Create UserModel from Firestore data
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      points: data['points'] ?? 0,
      queuePosition: data['queuePosition'] ?? 0,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
    );
  }

  /// Convert UserModel to Firestore data
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'points': points,
      'queuePosition': queuePosition,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Copy with updated values
  UserModel copyWith({
    String? name,
    String? email,
    int? points,
    int? queuePosition,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      points: points ?? this.points,
      queuePosition: queuePosition ?? this.queuePosition,
      createdAt: createdAt,
    );
  }
}
