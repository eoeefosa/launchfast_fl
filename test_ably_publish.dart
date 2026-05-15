import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Diagnostic script to verify if the backend is successfully publishing to Ably.
/// Run this from your local machine to test the connectivity of the backend-to-Ably bridge.
Future<void> testAblyPublishing({
  required String channelName,
  required String eventName,
  required Map<String, dynamic> data,
  required String backendUrl, // e.g., 'https://api.campuschow.app'
}) async {
  debugPrint('[Test] Publishing event $eventName to $channelName...');

  final dio = Dio();

  try {
    final response = await dio.post(
      '$backendUrl/debug/ably/publish',
      data: {
        'channel': channelName,
        'event': eventName,
        'data': data,
      },
    );

    if (response.statusCode == 200) {
      debugPrint('[Test] SUCCESS: Backend accepted publish request.');
    } else {
      debugPrint('[Test] FAILED: Server returned ${response.statusCode}: ${response.data}');
    }
  } catch (e) {
    debugPrint('[Test] ERROR: Could not reach backend: $e');
  }
}
