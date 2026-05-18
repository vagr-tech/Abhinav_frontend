// ignore: avoid_web_libraries_in_flutter
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, duplicate_ignore, prefer_const_constructors

import 'dart:html' as html;
import 'package:flutter/material.dart';

class WebLocationHelper {
  static Future<bool> isLocationBlocked() async {
    try {
      final permissions = html.window.navigator.permissions;
      if (permissions == null) return false;

      final status = await permissions.query({"name": "geolocation"});
      return status.state == "denied";
    } catch (_) {
      return false;
    }
  }

  static void openLocationSettings() {
    html.window.open("chrome://settings/content/location", "_blank");
  }

  static void showLocationBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Location Blocked"),
        content: const Text(
            "Browser blocked location. Enable it in settings and reload page."),
        actions: [
          TextButton(
            onPressed: openLocationSettings,
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
