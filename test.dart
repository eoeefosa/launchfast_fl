void main() {
  final List<dynamic> jsonStores = [
    {"id": "1"},
  ];
  try {
    List<String>.from(jsonStores);
  } catch (e) {
    // print(e.runtimeType);
    // print(e);
  }
}
