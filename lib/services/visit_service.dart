// ignore_for_file: unused_import, depend_on_referenced_packages, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';

class VisitService {
  static const String baseUrl = "https://abhinav-backend-z8tm.onrender.com/api";

  // --------------------------------------------------
  // UPLOAD PHOTO (MULTIPART) ✅ FINAL
  // --------------------------------------------------
  Future<String?> uploadPhoto(File file) async {
    final uri = Uri.parse("$baseUrl/visits/uploadPhoto");

    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer ${AuthService.token}";

    request.files.add(
      await http.MultipartFile.fromPath(
        "file", // 🔥 MUST MATCH multer.single("file")
        file.path,
      ),
    );

    final res = await request.send();
    final body = await res.stream.bytesToString();

    print("📸 UPLOAD STATUS => ${res.statusCode}");
    print("📸 UPLOAD BODY => $body");

    if (res.statusCode == 200) {
      final data = jsonDecode(body);
      return data["path"];
    }

    return null;
  }

  // --------------------------------------------------
  // SAVE VISIT LOG
  // --------------------------------------------------
  Future<bool> visitShop(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse("$baseUrl/visits/save"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      },
      body: jsonEncode(payload),
    );

    print("📝 VISIT STATUS => ${res.statusCode}");
    print("📝 VISIT BODY => ${res.body}");

    return res.statusCode == 200;
  }
}
