

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallButton extends StatelessWidget {
  final String phoneNumber;
  final bool isIOS;

  const CallButton({super.key, required this.phoneNumber, required this.isIOS});

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => launchUrl(Uri.parse('tel:$phoneNumber')),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            CupertinoIcons.phone_fill,
            color: Theme.of(context).colorScheme.surface,
            size: 20,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => launchUrl(Uri.parse('tel:$phoneNumber')),
      icon: Icon(
        Icons.phone_in_talk_rounded,
        color: Theme.of(context).colorScheme.surface,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
