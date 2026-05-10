class Rider {
  final String id;
  final String name;
  final String phoneNumber;
  final int capacity;

  Rider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.capacity,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      capacity: json['capacity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'capacity': capacity,
    };
  }
}
