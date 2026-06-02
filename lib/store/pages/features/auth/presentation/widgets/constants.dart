import 'package:flutter/material.dart';

abstract final class Validators {
  static FormFieldValidator<String> required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}

const networks = [
  {
    "name": "MTN",
    "prefix": [
      "0803",
      "0703",
      "0903",
      "0806",
      "0706",
      "0813",
      "0810",
      "0814",
      "0816",
      "0906",
      "0913",
      "0916",
      "0910",
      "0702",
    ],
  },
  {
    "name": "Airtel",
    "prefix": [
      "0802",
      "0808",
      "0708",
      "0812",
      "0701",
      "0902",
      "0901",
      "0904",
      "0907",
      "0912",
    ],
  },
  {
    "name": "Glo",
    "prefix": ["0805", "0807", "0705", "0815", "0811", "0905", "0915"],
  },
  {
    "name": "9mobile",
    "prefix": ["0809", "0818", "0817", "0909", "0908"],
  },
];
