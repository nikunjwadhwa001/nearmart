class Address {
  final String id;
  final String userId;
  final String label;
  final String addressLine;
  final String? city;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isDefault;

  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.addressLine,
    this.city,
    this.pincode,
    this.latitude,
    this.longitude,
    this.phone,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? 'Home',
      addressLine: json['address_line'] as String,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      phone: json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  /// Short display string for the address
  String get shortDisplay {
    final parts = <String>[addressLine];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }
}
