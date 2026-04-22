class LocationCluster {
  final String name;
  final List<String> locations;

  LocationCluster(this.name, this.locations);
}

final clusters = [
  LocationCluster("A", ["Hall 1", "Hall 2", "Hall 3", "Hall 5", "Hall 6", "Tedfund"]),
  LocationCluster("B", ["Hall 4", "Hall 7", "Hall 8"]),
  LocationCluster("C", ["Hall 3", "Faculty"]),
  LocationCluster("D", ["Tedfund", "Admin", "Hall 1"]),
];