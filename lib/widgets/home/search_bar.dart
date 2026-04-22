import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Search for food...',
            prefixIcon: Icon(Icons.search, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
