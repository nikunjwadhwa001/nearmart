// A MODEL is a Dart class that represents a piece of data
// Just like how a blueprint represents a building
// This tells Dart exactly what a "Shop" looks like

class Shop {
  // These are the properties of a shop
  // 'final' means once set, they never change
  final String id;
  final String name;
  final String? description;    // ? means this can be null (shop might not have a description)
  final String? phone;
  final double latitude;
  final double longitude;
  final String status;
  final bool isOpen;
  final String? logoUrl;
  final double? distance;       // Distance from customer in km

  // Constructor — how you create a Shop object
  // 'required' means you MUST provide this value
  const Shop({
    required this.id,
    required this.name,
    this.description,           // Not required because it's nullable
    this.phone,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isOpen,
    this.logoUrl,
    this.distance,
  });

  // fromJson — converts raw database data into a Shop object
  // Supabase returns data as Map<String, dynamic> (like a JSON object)
  // This factory method knows how to read that map
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      // json['id'] reads the 'id' field from the database row
      // as String — tells Dart what type to expect
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,  // ? because it can be null
      phone: json['phone'] as String?,
      // Database stores as decimal, Dart reads as double
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      isOpen: json['is_open'] as bool,
      logoUrl: json['logo_url'] as String?,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }

  // toJson — converts a Shop object back into a Map
  // Useful when you need to send data TO Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'is_open': isOpen,
      'logo_url': logoUrl,
    };
  }
}