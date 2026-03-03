class Profile {
  final String id;
  final String name;
  final String phone;
  final String role;

  Profile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  bool get isSeller => role == 'seller';
  bool get isUser => role == 'user';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }

  copyWith({required String name, required String phone}) {}
}
