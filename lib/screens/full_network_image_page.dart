import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullNetworkImagePage extends StatelessWidget {
  final String imageUrl;

  const FullNetworkImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: imageUrl.isEmpty
              ? const Text(
                  "No Photo Available",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
              : PhotoView(
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                ),
        ),
      ),
    );
  }
}
