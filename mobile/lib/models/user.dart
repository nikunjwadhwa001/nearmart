// User model representing data from public.users table
// This is different from Supabase's auth.User which only has id & email
// This model has the additional profile fields we store in our database

class User {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;  // 'customer', 'owner', or 'admin'
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  // Convert database JSON to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert User object to JSON for updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': isActive,
    };
  }

  // Helper to check user role
  bool get isCustomer => role == 'customer';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  // Copy with method - useful for updating specific fields
  User copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
