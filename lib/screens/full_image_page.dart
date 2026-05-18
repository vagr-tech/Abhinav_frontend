// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullImagePage extends StatelessWidget {
  final String base64Image;

  const FullImagePage({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Tap anywhere to close (UNCHANGED)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: PhotoView(
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                imageProvider: MemoryImage(
                  base64Decode(base64Image),
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              ),
            ),
          ),

          // ✅ Back Arrow Button (Premium Overlay)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
